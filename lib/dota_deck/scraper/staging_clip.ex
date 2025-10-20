defmodule DotaDeck.Scraper.StagingClip do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  schema "staging_clips" do
    field :hero_name, :string
    field :headline, :string
    field :audio_url, :string
    field :context, :string
    field :ability_name, :string
    field :hero_interaction, :string
    field :item_name, :string
    field :voiceline, :string
    field :filepath, :string
    field :processed, :boolean
    field :downloaded, :boolean
    timestamps()
  end

  def undownloaded() do
    DotaDeck.Scraper.StagingClip |> where([sc], sc.downloaded == false)
  end

  def downloaded_and_unprocessed() do
    DotaDeck.Scraper.StagingClip |> where([sc], sc.downloaded == true and sc.processed == false)
  end

  def changeset(staging_clip, attrs) do
    staging_clip
    |> cast(attrs, [:downloaded, :filepath])
    |> validate_required([:downloaded, :filepath])
    |> validate_length(:filepath, min: 1, allow_nil: true)
  end
end
