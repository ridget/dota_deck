defmodule DotaDeck.Repo.Migrations.CreateHeroes do
  use Ecto.Migration

  def change do
    create table(:heroes) do
      add :name, :string, null: false
      timestamps()
    end

    create index(:heroes, [:name])
  end
end
