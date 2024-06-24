defmodule Rafty.RegistryUtils do
  @registry :node_registry

  def get_other_nodes(current_node_id) do
    match_spec = [{{:"$1", :_, :_}, [], [:"$1"]}]
    Registry.select(@registry, match_spec)
    |> Enum.filter(fn node_id ->
      node_id != current_node_id
    end)
  end

  def find_node_process(node_name) do
    [{pid, _}] = Registry.lookup(@registry, node_name)
    pid
  end
end
