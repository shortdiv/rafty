defmodule Rafty.NodeSupervisor do
  use DynamicSupervisor

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_node(int) do
    spec = {Rafty.Counter, int}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
