defmodule Rafty.Node do
  use GenServer

  @heartbeat_interval 5000

  def start_link(arg) do
    # id = Keyword.get(opts, :id)
    GenServer.start_link(__MODULE__, arg, name: via_tuple(arg))
  end

  def get(pid) do
    GenServer.call(pid, :get)
  end

  @impl true
  def init(initial_state) do
    st = %{
      state: initial_state,
      timer: :erlang.start_timer(@heartbeat_interval, self(), :tick)
    }
    {:ok, st}
  end

  # switch the node to candidate on heartbeat timeout
  def get_state(id) do
    GenServer.call(via_tuple(id), :get_state)
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info({:timeout, _timer_ref, :tick}, st) do
    new_timer = :erlang.start_timer(@heartbeat_interval, self(), :tick)
    :erlang.cancel_timer(st.timer)
    {:noreply, %{st | timer: new_timer}}
  end

  defp via_tuple(id) do
    {:via, Registry, {Rafty.Registry, id}}
  end
end
