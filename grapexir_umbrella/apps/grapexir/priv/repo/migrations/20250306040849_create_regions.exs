defmodule Grapexir.Repo.Migrations.CreateRegions do
  use Ecto.Migration

  def up do
    create table(:regions) do
      add :name, :string, null: false
      add :latitude, :decimal, precision: 9, scale: 6, null: false
      add :longitude, :decimal, precision: 9, scale: 6, null: false

      timestamps()
    end

    create unique_index(:regions, [:latitude, :longitude])
  end

  def down do
    drop table(:regions)
  end
end
