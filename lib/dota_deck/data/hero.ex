defmodule DotaDeck.Data.Hero do
  use Ecto.Schema

  schema "heroes" do
    field :name, :string
    has_many :clips, DotaDeck.Data.Clip
    has_many :staging_clips, DotaDeck.Data.StagingClip
    timestamps()
  end
end
