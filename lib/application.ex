defmodule Rafty.Application do
  @moduledoc """
  Application module for the Raft application.
  """
  use Application

  def start(_type, _args) do
    children = [
      {Rafty.NodeSupervisor, []}
    ]

    opts = [strategy: :one_for_one, name: Rafty.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
