defmodule Grapexir.Repo.Migrations.CreateClimateRawRecords do
  use Ecto.Migration

  def up do
    create table(:climate_records) do
      add :date, :date, null: false
      add :temperature_model, :string, null: false
      add :max_temperature, :float, null: false

      add :region_id, references(:regions, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:climate_records, [:region_id, :date, :temperature_model])
  end

  def down do
    drop table(:climate_records)
  end
end
