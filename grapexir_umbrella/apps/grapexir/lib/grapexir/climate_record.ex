defmodule Grapexir.ClimateRecord do
  use Ecto.Schema
  import Ecto.Changeset

  @attributes [:region_id, :date, :temperature_model, :max_temperature]

  schema "climate_records" do
    field :date, :date
    field :temperature_model, :string
    field :max_temperature, :float

    belongs_to :region, Grapexir.Region

    timestamps()
  end

  def changeset(climate_record, attrs) do
    climate_record
    |> cast(attrs, @attributes)
    |> validate_required(@attributes)
    |> foreign_key_constraint(:region_id)
  end
end
