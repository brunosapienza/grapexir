defmodule Grapexir.DataIngestion.ClimateClient do
  @moduledoc """
  API wrapper for fetching climate data from the Open Meteo API.
  https://open-meteo.com/en/docs/climate-api
  """

  require Logger

  @base_url "https://climate-api.open-meteo.com/v1/climate?"
  @models "CMCC_CM2_VHR4,FGOALS_f3_H,HiRAM_SIT_HR,MRI_AGCM3_2_S,EC_Earth3P_HR,MPI_ESM1_2_XR,NICAM16_8S"

  # The climate data in this API is presented as daily aggregations. Multiple weather variables can be retrieved at once
  # E.g. temperature_2m_max, temperature_2m_min, temperature_2m_mean.
  # For now, we're only interested in the maximum temperature.
  @daily "temperature_2m_max"

  @doc """
  Fetches climate data for a given latitude and longitude within a specified date range.
  It ensures required parameters are present before making requests.
  Uses pattern matching for implicit validation to prevent calls with missing data.

  # It returns the following structure:
  %{
    "daily" => %{
      "temperature_2m_max_CMCC_CM2_VHR4" => [27.9, 27.4],
      "temperature_2m_max_EC_Earth3P_HR" => [27.8, 28.3],
      "time" => ["2025-01-01", "2025-01-02"]
    },
    "daily_units" => %{
      "temperature_2m_max_CMCC_CM2_VHR4" => "°C",
      "temperature_2m_max_EC_Earth3P_HR" => "°C",
      "temperature_2m_max_FGOALS_f3_H" => "°C",
      "temperature_2m_max_HiRAM_SIT_HR" => "°C",
      "temperature_2m_max_MPI_ESM1_2_XR" => "°C",
      "temperature_2m_max_MRI_AGCM3_2_S" => "°C",
      "temperature_2m_max_NICAM16_8S" => "°C",
      "time" => "iso8601"
    },
    "elevation" => 0.0,
    "generationtime_ms" => 55.89926242828369,
    "latitude" => 1.0,
    "longitude" => 1.0,
    "timezone" => "GMT",
    "timezone_abbreviation" => "GMT",
    "utc_offset_seconds" => 0
  }
  """
  def fetch_climate_data(%{ latitude: _lat, longitude: _lon, start_date: _start_date, end_date: _end_date } = params) do
    case HTTPoison.get(build_url(params)) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body }

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        { :error, "Failed to fetch data, status code: #{status_code}" }

      {:error, reason} ->
        { :error, "Error fetching data: #{reason}" }
    end
  end

  defp build_url(params) do
    url = @base_url <>
    URI.encode_query(%{
      latitude: params.latitude,
      longitude: params.longitude,
      start_date: params.start_date,
      end_date: params.end_date,
      models: @models,
      daily: @daily
    })

    Logger.info("Querying climate-api: #{url}")

    url
  end
end
