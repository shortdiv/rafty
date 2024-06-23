# probably not doing anything rn
defmodule Rafty.Registry do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: :registry)
  end

  def find_node(node_id) do
    GenServer.call(:registry, {:find_node, node_id})
  end

  def send(node, message) do
    case find_node(node) do
      nil -> {:error, "node is likely dead"}
      # pid -> GenServer.cast(pid, {:message, message})
      pid -> Kernel.send(pid, message)
    end
  end

  def init do
    {:ok, %{}}
  end
end
