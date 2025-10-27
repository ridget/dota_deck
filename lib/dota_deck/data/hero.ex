defmodule DotaDeck.Data.Hero do
  use Ecto.Schema
  import Ecto.Query

  schema "heroes" do
    field :name, :string
    has_many :clips, DotaDeck.Data.Clip
    has_many :staging_clips, DotaDeck.Data.StagingClip
    timestamps()
  end

  def list_all_heroes() do
    __MODULE__
    |> select([h], %{id: h.id, name: h.name})
  end
end
