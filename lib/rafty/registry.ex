# probably not doing anything rn
defmodule Rafty.Registry do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: :registry)
  end

  def whereis_name(node_id) do
    GenServer.call(:registry, {:whereis_name, node_id})
  end

  def register_name(node_id, pid) do
    GenServer.call(:registry, {:register_name, node_id, pid})
  end

  def unregister_name(node_id, pid) do
    GenServer.call(:registry, {:unregister_name, node_id, pid})
  end

  def send(node, message) do
    case whereis_name(node) do
      nil -> {:error, "node is likely dead"}
      # pid -> GenServer.cast(pid, {:message, message})
      pid ->
        Kernel.send(pid, message)
        pid
    end
  end

  def init(init_arg) do
    {:ok, init_arg}
  end
end
