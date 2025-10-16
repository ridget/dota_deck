defmodule DotaDeck.Clip do
  use Ecto.Schema

  schema "clips" do
    field :file_path, :string
    field :transcript, :string
    field :embedding, Pgvector.Ecto.Vector
    field :hero_name, :string
    field :interaction_type, :string
    field :inferred_archetype, :string
    field :primary_sentiment, :string
    field :secondary_sentiment, :string
    field :intents, {:array, :string}
    field :keywords, {:array, :string}
    field :themes, {:array, :string}
    timestamps()
  end
end
