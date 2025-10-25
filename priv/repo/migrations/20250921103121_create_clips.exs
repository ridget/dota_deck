defmodule DotaDeck.Repo.Migrations.CreateClips do
  use Ecto.Migration

  def change do
    create table(:clips) do
      add :filepath, :string, null: false
      add :transcript, :text
      # size MiniLM-L6-v2 provides
      add :embedding, :vector, size: 384
      add :raw_embedding, :string
      add :hero_id, references(:heroes, on_delete: :delete_all), null: false
      timestamps()
    end
    create index(:clips, ["embedding vector_cosine_ops"], using: :hnsw)
    create index(:clips, [:filepath])
    create index(:clips, [:hero_id])
    create index(:clips, [:raw_embedding])
  end
end
