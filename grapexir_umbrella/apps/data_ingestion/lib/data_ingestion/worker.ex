defmodule Grapexir.DataIngestion.Worker do
  @moduledoc """
  The main entry point for the data ingestion process.

  ## Responsibilities:
    - Orchestrates the data ingestion workflow.
    - Delegates data fetching and processing to the appropriate service modules.
    - Logs progress and errors.

  ## Design:
    - This module is part of the **Application Layer** in a DDD-inspired architecture.
    - It acts as a **use case handler**, coordinating steps without implementing business logic.

  ## Example Usage:
      Grapexir.DataIngestion.Worker.perform(%{args: %{"region_id" => 21}})
  """

  require Logger
  alias Grapexir.DataIngestion.{Parser, Service}

  @default_lookback_days 10958  # Default: 30 years

  @doc """
    Starts the data ingestion process for a given region.
      - Determines the appropriate date range for fetching missing data.
      - Uses a default lookback period if no previous data exists.

  ## Example
      Grapexir.DataIngestion.Worker.perform(%{args: %{"region_id" => 21}})
  """
  @spec perform(map(),module(),module()) :: {:ok, String.t()} | {:error, String.t()}
  def perform(%{args: %{"region_id" => region_id}}, service \\ Service, parser \\ Parser) do
    Logger.info("Starting data ingestion for region #{region_id}")

    with {:ok, region} <- service.fetch_region(region_id),
         {start_date, end_date} <- service.get_date_range(region_id, @default_lookback_days),
         {:ok, body} <- service.fetch_climate_data(region, start_date, end_date),
         {:ok, changesets} <- parser.parse_and_build_changesets(body, region_id),
         {:ok, _} <- service.create_climate_records(changesets) do
      Logger.info("Data ingestion completed for #{region_id}")
      {:ok, "Data ingestion completed"}
    else
      {:error, error} ->
        Logger.error("Data ingestion failed: #{error}")
        {:error, error}
    end
  end
end
