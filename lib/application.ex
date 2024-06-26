defmodule Rafty.Application do
  @moduledoc """
  Application module for the Raft application.
  """
  use Application

  @registry :node_registry

  def start(_type, _args) do
    args = System.argv()
    num_nodes = parse_args(args)

    children = [
      {Registry, [keys: :unique, name: @registry]},
      {Rafty.NodeSupervisor, num_nodes}
    ]

    opts = [strategy: :one_for_one, name: Rafty.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp parse_args(args) do
    case args do
      [nodes] ->
        String.to_integer(nodes)
      _ ->
        3
    end
  end
end
