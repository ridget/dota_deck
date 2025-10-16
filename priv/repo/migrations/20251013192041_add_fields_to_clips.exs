defmodule DotaDeck.Repo.Migrations.AddFieldsToClips do
  use Ecto.Migration

  def change do
    alter table(:clips) do
      add :interaction_type, :string
      add :themes, {:array, :string}, default: []
      add :keywords, {:array, :string}, default: []
      add :intents, {:array, :string}, default: []
      add :inferred_archetype, :string
      add :primary_sentiment, :string
      add :secondary_sentiment, :string
      add :hero_name, :string
    end
    create index(:clips, [:interaction_type])
    create index(:clips, [:inferred_archetype])
    create index(:clips, [:themes], using: :gin)
    create index(:clips, [:keywords], using: :gin)
    create index(:clips, [:intents], using: :gin)
    create index(:clips, [:primary_sentiment])
    create index(:clips, [:secondary_sentiment])
    create index(:clips, [:hero_name])
  end
end
