defmodule Rafty.RegistryUtils do
  @registry :node_registry

  def get_other_nodes(current_node_id) do
    match_spec = [{{:"$1", :_, :_}, [], [:"$1"]}]
    all_nodes = Registry.select(@registry, match_spec)

    Enum.filter(all_nodes, fn node_id ->
      node_id != current_node_id
    end)
  end
end
