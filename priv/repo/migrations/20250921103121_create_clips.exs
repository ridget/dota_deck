defmodule DotaDeck.Repo.Migrations.CreateClips do
  use Ecto.Migration

  def change do
    create table(:clips) do
      add :filepath, :string, null: false
      add :transcript, :text
      add :original_transcript, :text
      # size MiniLM-L6-v2 provides
      add :context_embedding, :vector, size: 384
      add :context_raw_embedding, :text
      add :embedding, :vector, size: 384
      add :hero_id, references(:heroes, on_delete: :delete_all), null: false
      timestamps()
    end

    execute """
    CREATE INDEX clips_transcript_tsvector_idx
    ON clips
    USING GIN (to_tsvector('english', transcript));
    """

    execute """
    CREATE INDEX clips_original_transcript_tsvector_idx
    ON clips
    USING GIN (to_tsvector('english', original_transcript));
    """
    create index(:clips, ["context_embedding vector_cosine_ops"], using: :hnsw)
    create index(:clips, ["embedding vector_cosine_ops"], using: :hnsw)
    create index(:clips, [:filepath])
    create index(:clips, [:original_transcript])
    create index(:clips, [:hero_id])
    create index(:clips, [:context_raw_embedding])
  end
end
