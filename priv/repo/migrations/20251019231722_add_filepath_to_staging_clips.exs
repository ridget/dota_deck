defmodule DotaDeck.Repo.Migrations.AddFilepathToStagingClips do
  use Ecto.Migration

  def change do
    alter table(:staging_clips) do
      add :filepath, :string
    end

    create index(:staging_clips, [:filepath])
  end
end
