defmodule Grapexir.DataIngestion.Parser do
  alias Grapexir.ClimateRecord

  @doc """
    Parses the JSON body received from the API and extracts climate data.

    Example input:
      body = "{"daily": {"time": ["2025-03-01", "2025-03-02"], "temperature": [30, 32]}}"
      region_id = 1

    Example output:
      {:ok, [%ClimateRecord{date: "2025-03-01", max_temperature: 30, region_id: 1},
            %ClimateRecord{date: "2025-03-02", max_temperature: 32, region_id: 1}]}

    If parsing fails, it returns:
      {:error, "Error parsing data: <error details>"}

    The function ensures that only valid climate data is processed into changesets.
  """
  @spec parse_and_build_changesets(binary(), integer()) :: {:ok, Enumerable.t(Ecto.Changeset.t())} | {:error, String.t()}
  def parse_and_build_changesets(body, region_id) do
    case Jason.decode(body) do
      {:ok, %{"daily" => %{"time" => dates} = daily_data}} ->
        {:ok, build_changesets(dates, region_id, Map.drop(daily_data, ["time"]))}
      {:error, error} -> {:error, "Error parsing data: #{inspect(error)}"}
    end
  end

  # Builds a list of Ecto changesets for inserting climate records.

  # Example input:
  #   dates = ["2025-03-01", "2025-03-02"]
  #   region_id = 1
  #   daily_data = %{ "temperature" => [30, 32] }

  # Example output:
  #   [%Ecto.Changeset{valid?: true, changes: %{date: "2025-03-01", max_temperature: 30, region_id: 1}},
  #   %Ecto.Changeset{valid?: true, changes: %{date: "2025-03-02", max_temperature: 32, region_id: 1}}]

  # This function maps over the climate data, aligning dates with temperature values
  # and creating changesets for batch insertion into the database.

  @spec build_changesets([String.t()], integer(), map()) :: Enumerable.t(Ecto.Changeset.t())
  defp build_changesets(dates, region_id, daily_data) do
    # Converts the list of dates into a tuple for fast indexed access.
    dates_tuple = List.to_tuple(dates)

    Stream.flat_map(daily_data, fn {key, values} ->
      Stream.with_index(values, fn value, index ->
        attrs = %{
          date: elem(dates_tuple, index),
          temperature_model: key,
          max_temperature: value,
          region_id: region_id
        }

        ClimateRecord.changeset(%ClimateRecord{}, attrs)
      end)
    end)
  end
end
