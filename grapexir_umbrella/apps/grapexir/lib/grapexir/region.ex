defmodule Grapexir.Region do
  use Ecto.Schema
  import Ecto.Changeset

  @attributes [:name, :lat, :long]

  schema "regions" do
    field :name, :string
    field :latitude, :decimal
    field :longitude, :decimal
    timestamps()
  end

  def changeset(climate_record, attrs) do
    climate_record
    |> cast(attrs, @attributes)
    |> validate_required(@attributes)
  end
end
