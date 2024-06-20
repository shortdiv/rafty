defmodule Rafty.Node do
  use GenServer

  @heartbeat_interval 5000
  @election_timeout 4000

  def start_link(opts \\ []) do
    id = Keyword.get(opts, :id)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(id))
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  @impl true
  def init(initial_state) do
    st = %{
      role: initial_state[:role],
      heartbeat_timer: :erlang.start_timer(randomize_timeout(@heartbeat_interval, 0.4), self(), :heartbeat_timeout),
      election_timer: nil,
      node_id: initial_state[:id],
    }
    {:ok, st}
  end

  def get_state(id) do
    GenServer.call(via_tuple(id), :get_state)
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_info({:timeout, _timer_ref, :election_timeout}, st) do
    IO.puts("starting an election! #{st.node_id}")
    {:noreply, st}
  end

  @impl true
  def handle_info({:timeout, _timer_ref, :heartbeat_timeout}, st) do
    IO.puts("heartbeat exceeded")
    # start an election!
    :erlang.cancel_timer(st.heartbeat_timer)
    {:noreply, %{st | election_timer: :erlang.start_timer(randomize_timeout(@election_timeout, 0.4), self(), :election_timeout)}}
  end

  defp via_tuple(id) do
    {:via, Registry, {Rafty.Registry, id}}
  end

  def randomize_timeout(timeout, within_range) do
    {rangemax, rangemin} = {1.0 + within_range, 1.0 - within_range}
    max = round(timeout * rangemax)
    min = round(timeout * rangemin)
    min + :rand.uniform(max - min)
  end
end
