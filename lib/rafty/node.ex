defmodule Rafty.Node do
  use GenServer

  require Logger

  @heartbeat_interval 5000
  @election_timeout 4000
  @registry :node_registry
  @candidate_role :candidate

  def start_link(opts \\ []) do
    id = Keyword.get(opts, :id)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(id))
  end

  def stop(name) do
    Logger.info("Stopping #{inspect(name)}")
    GenServer.stop(via_tuple(name))
  end

  def crash(name), do: GenServer.cast(via_tuple(name), :raise)

  def request_vote(pid, candidate_term, candidate_id) do
    GenServer.call(pid, {:request_vote, self(), candidate_term, candidate_id})
  end

  def vote_received(pid, somedata) do
    GenServer.cast(pid, {:vote_received, somedata})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  @impl true
  def init(initial_state) do
    Logger.info("Starting #{inspect(initial_state[:id])}")
    st = %{
      role: initial_state[:role],
      heartbeat_timer: :erlang.start_timer(randomize_timeout(@heartbeat_interval, 0.4), self(), :heartbeat_timeout),
      election_timer: nil,
      current_term: 0,
      voted_for: nil,
      votes_received: 0,
      node_id: "node_#{initial_state[:id]}",
    }
    {:ok, st}
  end

  def schedule, do: Process.send_after(self(), :send_heartbeat, 2000)

  def handle_info({:timeout, _timer_ref, :election_timeout}, state) do
    if state.voted_for == nil do
      Logger.info("Election timed out, starting an election")
      state = Map.put(state, :current_term, state.current_term + 1)
      Rafty.RegistryUtils.get_other_nodes(state.node_id)
      |> Enum.each(fn node ->
        process = Rafty.RegistryUtils.find_node_process(node)
        request_vote(process, state.current_term, state.node_id)
        end)
      {:noreply, %{state | role: @candidate_role}}
    else
      Logger.info("Node is ineligible for candidacy")
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:timeout, _timer_ref, :heartbeat_timeout}, st) do
    Logger.info("Heartbeat timeout for #{st.node_id} exceeded")
    :erlang.cancel_timer(st.heartbeat_timer)
    {:noreply, %{st | election_timer: :erlang.start_timer(randomize_timeout(@election_timeout, 0.4), self(), :election_timeout)}}
  end

  @impl true
  def handle_call({:request_vote, pid, candidate_term, candidate_id}, _from, state) do
    {reply, new_state} =
      if candidate_term > state.current_term and state.voted_for == nil do
        vote_received(pid, %{})
        # cancel election timer
        if state.election_timer != nil, do: :erlang.cancel_timer(state.election_timer)
        {:ok, %{state | voted_for: candidate_id, current_term: candidate_term}}
      else
        {:error, state}
      end

    {:reply, reply, new_state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_info(:send_heartbeat, state) do
    if state.role == :leader do

      schedule()

      Rafty.RegistryUtils.get_other_nodes(state.node_id)
      |> Enum.each(fn node ->
        process = Rafty.RegistryUtils.find_node_process(node)
        GenServer.cast(process, {:heartbeat, state.current_term})
        end)
      {:noreply, state}
    else
      {:noreply, state}
    end
  end

  def handle_cast({:heartbeat, term}, state) do
    Logger.info("Received heartbeat from leader with term #{term} #{state.node_id}}")

    :erlang.cancel_timer(state.heartbeat_timer)

    new_state = %{state | heartbeat_timer: :erlang.start_timer(randomize_timeout(@heartbeat_interval, 0.4), self(), :heartbeat_timeout), current_term: term, votes_received: 0, voted_for: nil}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:vote_received, _data}, state) do
    votes_received = state.votes_received + 1
    state = %{state | votes_received: votes_received}
    if votes_received > div(length(Rafty.RegistryUtils.get_other_nodes(state.node_id)), 2) do
      Logger.info("a leader has been chosen in #{state.node_id}")
      :erlang.cancel_timer(state.heartbeat_timer)

      schedule()

      {:noreply, %{state | role: :leader, election_timer: nil, heartbeat_timer: nil}}
    else
      {:noreply, %{state | role: :follower, election_timer: nil, heartbeat_timer: :erlang.start_timer(randomize_timeout(@heartbeat_interval, 0.4), self(), :heartbeat_timeout)}}
    end
  end

  defp via_tuple(id) do
    node_name = "node_#{id}"
    {:via, Registry, {@registry, node_name}}
  end

  def randomize_timeout(timeout, within_range) do
    {rangemax, rangemin} = {1.0 + within_range, 1.0 - within_range}
    max = round(timeout * rangemax)
    min = round(timeout * rangemin)
    min + :rand.uniform(max - min)
  end
end
