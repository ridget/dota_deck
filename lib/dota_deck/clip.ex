defmodule DotaDeck.Clip do
  use Ecto.Schema

  schema "clips" do
    field :file_path, :string
    field :transcript, :string
    field :embedding, Pgvector.Ecto.Vector
    timestamps()
  end
end
