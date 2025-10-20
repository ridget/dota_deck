defmodule DotaDeck.Repo.Migrations.AddProcessingAttributesToStagingClips do
  use Ecto.Migration

  def change do
    alter table(:staging_clips) do
      add :processed, :boolean, default: false, null: false
      add :downloaded, :boolean, default: false, null: false
    end
  end
end
