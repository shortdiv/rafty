defmodule Rafty.NodeSupervisor do
  use Supervisor
  @default_role :follower

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  # def start_node(int) do
  #   spec = {Rafty.Node, int}
  #   Supervisor.start_child(__MODULE__, spec)
  # end

  def start_child(child_name) do
    Supervisor.start_child(
      __MODULE__,
      %{id: Node, start: {Node, :start_link,  [child_name]}, restart: :transient})
  end

  @impl true
  def init(num_nodes) do
    children = for node <- 1..num_nodes do
      Supervisor.child_spec({Rafty.Node,
      [
        id: node,
        role: @default_role,
        data: %{}
      ]},
      id: node)
    end
    Supervisor.init(children, strategy: :one_for_one)
  end
end
