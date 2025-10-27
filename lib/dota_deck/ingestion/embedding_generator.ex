defmodule DotaDeck.Ingestion.EmbeddingGenerator do
  def generate(changeset_map, llm_metadata_map) do
    all_fields =
      Enum.flat_map([changeset_map, llm_metadata_map], &Map.to_list/1)

    field_order_narrative = [
      {:voiceline, "transcript"},
      {:summary, "summary"},
      {:intent, "intent"},
      {:theme, "theme"},
      {:emotion, "emotion"}
    ]

    final_string =
      Enum.reduce(field_order_narrative, [], fn {key, prefix}, acc ->
        case List.keyfind(all_fields, key, 0) do
          {^key, value} when is_binary(value) and value != "" ->
            ["#{prefix}: #{value}"] ++ acc

          _ ->
            acc
        end
      end)
      |> Enum.reverse()
      |> Enum.join(". ")
      |> String.replace("..", ".")

    final_string
  end
end
