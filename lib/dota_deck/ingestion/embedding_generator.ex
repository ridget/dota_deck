defmodule DotaDeck.Ingestion.EmbeddingGenerator do
  def generate(changeset_map, llm_metadata_map) do
    all_fields =
      Enum.flat_map([changeset_map, llm_metadata_map], &Map.to_list/1)

    field_order = [
      {:hero_name, "HERO"},
      {:headline, "HEADLINE"},
      {:context, "CONTEXT"},
      {"emotion", "EMOTION"},
      {"intent", "INTENT"},
      {"theme", "THEME"},
      {"summary", "SUMMARY"},
      {:ability_name, "ABILITY"},
      {:item_name, "ITEM"},
      {:hero_interaction, "INTERACTION"},
      {:voiceline, "TRANSCRIPT"}
    ]

    final_string =
      Enum.reduce(field_order, [], fn {key, prefix}, acc ->
        case List.keyfind(all_fields, key, 0) do
          {^key, value} when is_binary(value) and value != "" ->
            ["#{prefix}: #{value}."] ++ acc

          _ ->
            acc
        end
      end)
      |> Enum.reverse()
      |> Enum.join(" ")

    final_string
  end
end
