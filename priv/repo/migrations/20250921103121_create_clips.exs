defmodule DotaDeck.Repo.Migrations.CreateClips do
  use Ecto.Migration

  def change do
    create table(:clips) do
      add :file_path, :string, null: false
      add :transcript, :text
      add :embedding, :vector, size: 384
      add :inserted_at, :utc_datetime, null: false
      add :updated_at, :utc_datetime, null: false
    end
    create index(:clips, ["embedding vector_cosine_ops"], using: :hnsw)
    create index(:clips, [:file_path])
  end
end
