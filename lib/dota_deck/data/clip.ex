defmodule DotaDeck.Data.Clip do
  use Ecto.Schema
  import Ecto.Query
  import Pgvector.Ecto.Query

  schema "clips" do
    field :filepath, :string
    field :original_transcript, :string
    field :transcript, :string
    field :context_embedding, Pgvector.Ecto.Vector
    field :embedding, Pgvector.Ecto.Vector
    field :context_raw_embedding, :string
    belongs_to :hero, DotaDeck.Data.Hero
    timestamps()
  end

  def find_by_embedding(embedding, hero_id) do
    __MODULE__
    |> filter_by_hero_id(hero_id)
    |> order_by_embedding(embedding)
  end

  defp order_by_embedding(query, embedding) do
    from c in query,
      order_by: cosine_distance(c.context_embedding, ^embedding),
      limit: 25
  end

  defp filter_by_hero_id(query, hero_id) when is_integer(hero_id) do
    from c in query,
      inner_join: h in assoc(c, :hero),
      where: h.id == ^hero_id
  end

  defp filter_by_hero_id(query, _) do
    query
  end
end
