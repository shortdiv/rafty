defmodule Raft.Application do
  @moduledoc """
  Application module for the Raft application.
  """
  use Application

  def start(_type, _args) do
    children = [
      {Raft.MyGenserver, []}
    ]

    opts = [strategy: :one_for_one, name: Raft.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
