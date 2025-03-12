defmodule Grapexir.DataIngestion.Service do
  @moduledoc """
  Handles domain logic related to fetching regions, calling external APIs, and persisting data.

  ## Responsibilities:
    - Fetches region data from the database.
    - Calls external APIs to retrieve climate data.
    - Inserts data into the database in an optimized manner.

  ## Design:
    - This module is similar to a **Service class in DDD**.
    - It belongs to the **Domain Layer**, encapsulating business logic and interactions with external systems.
    - It should not contain database models, only use them.

  ## Why This Design?
    - By keeping this separate, we ensure that the `Worker` module remains focused on orchestration.
    - Service modules help keep business logic reusable, testable, and decoupled.
  """

  alias Grapexir.Repo
  alias Grapexir.ClimateRecord
  import Ecto.Query

  @spec fetch_region(integer()) :: {:ok, any()} | {:error, String.t()}
  def fetch_region(region_id) do
    case Repo.get(Grapexir.Region, region_id) do
      nil -> {:error, "Region not found"}
      region -> {:ok, region}
    end
  end

  @doc """
    Determines the start and end dates for querying new records.
  """
  @spec get_date_range(integer(), integer()) :: {Date.t(), Date.t()}
  def get_date_range(region_id, lookback_days) do
    today = Date.utc_today()

    last_recorded_date = get_last_recorded_date(region_id)
    first_recorded_date = get_first_recorded_date(region_id)

    cond do
      # No data at all, fetch full history based on lookback_days
      last_recorded_date == nil ->
        {Date.add(today, -lookback_days), today}

      # First recorded data is too recent, so fetch missing history
      # For instance, if we want 90 days of history and the first_recorded_data is from
      # 30 days ago, we go 60 days ago from first_recorded date.
      Date.compare(Date.add(today, -lookback_days), first_recorded_date) == :lt ->
        {Date.add(today, -(lookback_days - Date.diff(today, first_recorded_date))), today}

      # We have a valid data range, but need to fetch only missing records.
      # Example: We need to fetch missing records from either today or the day before.
      # To ensure we don't build a bad_request with `start_date: tomorrow`, we use min/2
      # to make sure start_date is never after today.
      #
      # P.S. If data is up to date and the worker runs again, it will re-query today's data.
      true ->
        start_date =
          case Date.compare(Date.add(last_recorded_date, 1), today) do
            :gt -> today   # If last recorded date + 1 is after today, use today
            _ -> Date.add(last_recorded_date, 1)  # Otherwise, use last recorded date + 1
          end

        {start_date, today}
    end
  end

  @type region :: %Grapexir.Region{}
  @spec fetch_climate_data(region, Date.t(), Date.t(), module()) :: {:ok, binary()} | {:error, String.t()}
  def fetch_climate_data(%Grapexir.Region{} = region, start_date, end_date, client \\ Grapexir.DataIngestion.ClimateClient) do
    client.fetch_climate_data(%{latitude: region.latitude, longitude: region.longitude, start_date: start_date, end_date: end_date})
  end

  @spec create_climate_records(Enumerable.t(Ecto.Changeset.t())) :: {:ok, String.t()} | {:error, String.t()}
  def create_climate_records(record_stream) do
    case Repo.transaction(fn ->
      record_stream
      |> Stream.chunk_every(1000)
      |> Stream.each(&insert_batch/1)
      |> Stream.run()
    end) do
      {:ok, _} -> {:ok, "Data ingestion completed"}
      {:error, error} -> {:error, "Error inserting data: #{inspect(error)}"}
    end
  end

  @spec insert_batch([Ecto.Changeset.t()]) :: :ok | {:error, String.t()}
  def insert_batch(changeset_list) do
    multi =
      Enum.reduce(changeset_list, Ecto.Multi.new(), fn changeset, multi ->
        Ecto.Multi.insert(multi, System.unique_integer([:positive]), changeset,
          on_conflict: :nothing, conflict_target: [:region_id, :date, :temperature_model])
      end)

    case Repo.transaction(multi) do
      {:ok, _} -> :ok
      {:error, _operation, failed_changeset, _} ->
        Repo.rollback(failed_changeset.errors)
    end
  end

  def get_last_recorded_date(region_id), do: get_recorded_date(region_id, :desc)
  def get_first_recorded_date(region_id), do: get_recorded_date(region_id, :asc)

  defp get_recorded_date(region_id, order) when order in [:asc, :desc] do
    Repo.one(
      from cr in ClimateRecord,
      where: cr.region_id == ^region_id,
      order_by: [{^order, cr.date}],
      limit: 1,
      select: cr.date
    )
  end
end
