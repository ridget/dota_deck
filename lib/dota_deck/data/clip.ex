defmodule DotaDeck.Data.Clip do
  use Ecto.Schema
  import Ecto.Query
  import Pgvector.Ecto.Query

  schema "clips" do
    field :filepath, :string
    field :transcript, :string
    field :embedding, Pgvector.Ecto.Vector
    field :raw_embedding, :string
    belongs_to :hero, DotaDeck.Data.Hero
    timestamps()
  end

  def find_by_embedding(embedding, hero_name) do
    __MODULE__
    |> filter_by_hero_name(hero_name)
    |> order_by_embedding(embedding)
  end

  defp order_by_embedding(query, embedding) do
    from c in query,
      order_by: cosine_distance(c.embedding, ^embedding),
      limit: 25
  end

  defp filter_by_hero_name(query, nil) do
    query
  end

  defp filter_by_hero_name(query, hero_name) when is_binary(hero_name) do
    from c in query,
      inner_join: h in assoc(c, :hero),
      where: h.name == ^hero_name
  end
end
