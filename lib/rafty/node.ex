defmodule Rafty.Node do
  use GenServer

  require Logger

  @heartbeat_interval 5000
  @election_timeout 4000
  @registry :node_registry

  def start_link(opts \\ []) do
    id = Keyword.get(opts, :id)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(id))
  end

  @impl true
  def init(initial_state) do
    Logger.info("Starting #{inspect(initial_state[:id])}")
    st = %{
      role: initial_state[:role],
      heartbeat_timer: :erlang.start_timer(randomize_timeout(@heartbeat_interval, 0.4), self(), :heartbeat_timeout),
      election_timer: nil,
      node_id: "node_#{initial_state[:id]}",
    }
    {:ok, st}
  end

  def stop(name) do
    Logger.info("Stopping #{inspect(name)}")
    GenServer.stop(via_tuple(name))
  end

  def crash(name), do: GenServer.cast(via_tuple(name), :raise)

  def handle_info({:timeout, _timer_ref, :election_timeout}, st) do
    IO.puts("starting an election! #{st.node_id}")
    Rafty.RegistryUtils.get_other_nodes(st.node_id)
    |> Enum.each(fn node ->
      process = Rafty.RegistryUtils.find_node_process(node)
      send(process, {:message, "Hello from #{st.node_id}"})
      end)
    {:noreply, st}
  end

  @impl true
  def handle_info({:timeout, _timer_ref, :heartbeat_timeout}, st) do
    IO.puts("heartbeat exceeded")
    # start an election!
    :erlang.cancel_timer(st.heartbeat_timer)
    {:noreply, %{st | election_timer: :erlang.start_timer(randomize_timeout(@election_timeout, 0.4), self(), :election_timeout)}}
  end

  def handle_info({:message, message}, state) do
    IO.inspect("#{message} received by #{state.node_id}")
    {:noreply, state}
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
