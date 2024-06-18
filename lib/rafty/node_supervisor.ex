defmodule Rafty.NodeSupervisor do
  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_node(int) do
    spec = {Rafty.Counter, int}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @impl true
  def init(start_numbers) do
    children = for start <- start_numbers do
      Supervisor.child_spec({Rafty.Counter, start}, id: start)
    end
    Supervisor.init(children, strategy: :one_for_one)
  end
end
