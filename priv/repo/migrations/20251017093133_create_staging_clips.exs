defmodule DotaDeck.Repo.Migrations.CreateStagingClips do
  use Ecto.Migration

  def change do
    create table(:staging_clips) do
      add :headline, :text, null: false
      add :audio_url, :text, null: false
      add :context, :text
      add :ability_name, :text
      add :hero_interaction, :text
      add :voiceline, :text
      add :item_name, :text
      add :filepath, :string
      add :hero_id, references(:heroes, on_delete: :delete_all), null: false
      add :processed, :boolean, default: false, null: false
      add :downloaded, :boolean, default: false, null: false
      timestamps()
    end

    create index(:staging_clips, [:filepath])
    create index(:staging_clips, [:audio_url])
    create index(:staging_clips, [:voiceline])
  end
end
