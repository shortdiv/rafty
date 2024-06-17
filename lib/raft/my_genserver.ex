defmodule Raft.MyGenserver do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end
end
