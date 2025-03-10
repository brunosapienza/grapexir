defmodule Grapexir.DataIngestion.ServiceTest do
  use Grapexir.DataCase, async: true

  alias Grapexir.DataIngestion.Service
  alias Grapexir.{Repo, Region, ClimateRecord}

  describe "fetch_region/1" do
    test "returns region when found" do
      region = %Region{name: "McLaren Vale, South Australia", id: 21, latitude: 12.34, longitude: 56.78} |> Repo.insert!()

      assert {:ok, found_region} = Service.fetch_region(21)
      assert found_region.id == region.id
    end

    test "returns error when region is not found" do
      assert Service.fetch_region(99) == {:error, "Region not found"}
    end
  end

  describe "get_last_recorded_date/1" do
    setup do
      region = %Region{name: "McLaren Vale, South Australia", latitude: 12.34, longitude: 56.78}  |> Repo.insert!()
      {:ok, region: region}
    end

    test "returns the most recent date when records exist", %{region: region} do
      %ClimateRecord{region_id: region.id, date: ~D[2025-03-05], temperature_model: "a", max_temperature: 2.5} |> Repo.insert!()
      %ClimateRecord{region_id: region.id, date: ~D[2025-03-10], temperature_model: "a", max_temperature: 2.5} |> Repo.insert!()

      assert Service.get_last_recorded_date(region.id) == ~D[2025-03-10]
    end

    test "returns nil when no records exist", %{region: region} do
      assert Service.get_last_recorded_date(region.id) == nil
    end
  end

  describe "get_first_recorded_date/1" do
    setup do
      region = %Region{name: "McLaren Vale, South Australia", latitude: 12.34, longitude: 56.78}  |> Repo.insert!()
      {:ok, region: region}
    end

    test "returns the most recent date when records exist", %{region: region} do
      %ClimateRecord{region_id: region.id, date: ~D[2025-03-05], temperature_model: "a", max_temperature: 2.5} |> Repo.insert!()
      %ClimateRecord{region_id: region.id, date: ~D[2025-03-10], temperature_model: "a", max_temperature: 2.5} |> Repo.insert!()

      assert Service.get_first_recorded_date(region.id) == ~D[2025-03-05]
    end

    test "returns nil when no records exist", %{region: region} do
      assert Service.get_first_recorded_date(region.id) == nil
    end
  end

  describe "get_date_range/2" do
    setup do
      today = ~D[2025-03-10]
      {:ok, today: today}
    end

    test "returns full lookback range when no records exist", %{today: today} do
      assert Service.get_date_range(21, 90) == {Date.add(today, -90), today}
    end

    test "fetches extra missing history when first recorded date is too recent", %{today: today} do
      lookback_days = 90

      region = %Region{name: "McLaren Vale, South Australia", latitude: 12.34, longitude: 56.78}  |> Repo.insert!()
      %ClimateRecord{region_id: region.id, date: Date.add(today, -30), temperature_model: "a", max_temperature: 2.5} |> Repo.insert!()

      expected_start_date = Date.add(today, -60) # Go further back to maintain 90 days

      assert Service.get_date_range(region.id, lookback_days) == {expected_start_date, today}
    end

    test "fetches missing records when last recorded date exists within 90 days", %{today: today} do
      lookback_days = 90

      region = %Region{name: "McLaren Vale, South Australia", latitude: 12.34, longitude: 56.78} |> Repo.insert!()

      # make sure the lookback range is covered
      %ClimateRecord{region_id: region.id, date: Date.add(today, -lookback_days), temperature_model: "a", max_temperature: 2.5} |> Repo.insert!()

      # make sure latest entry is from 5 days ago
      %ClimateRecord{region_id: region.id, date: Date.add(today, -5), temperature_model: "a", max_temperature: 2.5} |> Repo.insert!()

      # expect start_date to be based on the last recorded day + 1
      expected_start_date = Date.add(today, -4)

      assert Service.get_date_range(region.id, lookback_days) == {expected_start_date, today}
    end

    test "ensures start_date is never after today", %{today: today} do
      lookback_days = 90

      region = %Region{name: "McLaren Vale, South Australia", latitude: 12.34, longitude: 56.78} |> Repo.insert!()

      # make sure the lookback range is covered
      %ClimateRecord{region_id: region.id, date: Date.add(today, -lookback_days), temperature_model: "a", max_temperature: 2.5} |> Repo.insert!()

      # make sure data from today has already been fetched
      %ClimateRecord{region_id: region.id, date: today, temperature_model: "a", max_temperature: 2.5} |> Repo.insert!()

      assert Service.get_date_range(region.id, lookback_days) == {today, today}
    end

    test "handles a case where first_recorded_date is much older than lookback_days", %{today: today} do
      lookback_days = 90

      region = %Region{name: "McLaren Vale, South Australia", latitude: 12.34, longitude: 56.78} |> Repo.insert!()
      %ClimateRecord{region_id: region.id, date: Date.add(today, lookback_days + 150), temperature_model: "a", max_temperature: 2.5} |> Repo.insert!()

      expected_start_date = Date.add(today, -lookback_days) # Should not go further back than lookback_days

      assert Service.get_date_range(26, 90) == {expected_start_date, today}
    end
  end

  describe "fetch_climate_data/3" do
    setup do
      defmodule MockClimateClient do
        def fetch_climate_data(params) do
          send(self(), {:fetch_climate_data_called, params})
          {:ok, "{\"mocked\": \"data\"}"}
        end
      end

      {:ok, mock_client: MockClimateClient}
    end

    test "calls the API with correct parameters and returns mock response", %{mock_client: mock_client} do
      region = %Region{name: "McLaren Vale, South Australia", latitude: 12.34, longitude: 56.78} |> Repo.insert!()
      start_date = ~D[2025-03-01]
      end_date = ~D[2025-03-10]

      expected_params = %{latitude: 12.34, longitude: 56.78, start_date: start_date, end_date: end_date}

      # Call function with the mock client
      assert {:ok, _} = Service.fetch_climate_data(region, start_date, end_date, mock_client)

      # Assert that the mock function was called with the expected parameters
      assert_received {:fetch_climate_data_called, ^expected_params}
    end
  end

  describe "create_climate_records/1" do
    setup do
      region = %Region{name: "McLaren Vale, South Australia", latitude: 12.34, longitude: 56.78} |> Repo.insert!()

      {:ok, region: region}
    end

    test "returns success when transaction completes with valid changesets", %{region: region} do
      changesets = [
        ClimateRecord.changeset(%ClimateRecord{}, %{
          date: ~D[2025-03-01],
          temperature_model: "A",
          max_temperature: 22.1,
          region_id: region.id
        })
      ]

      assert Service.create_climate_records(changesets) == {:ok, "Data ingestion completed"}
    end

    test "returns error when transaction fails", %{region: region} do
      changesets = [
        ClimateRecord.changeset(%ClimateRecord{}, %{
          date: nil, # Invalid data (date is required)
          temperature_model: "A",
          max_temperature: 22.1,
          region_id: region.id
        })
      ]

      assert {:error, _} = Service.create_climate_records(changesets)
    end
  end

  describe "insert_batch/1" do
    test "successfully inserts records in a batch" do
      region = %Region{name: "McLaren Vale, South Australia", latitude: 12.34, longitude: 56.78} |> Repo.insert!()

      changesets = [
        ClimateRecord.changeset(%ClimateRecord{}, %{
          date: ~D[2025-03-01],
          temperature_model: "A",
          max_temperature: 22.1,
          region_id: region.id
        })
      ]

      assert Service.insert_batch(changesets) == :ok
    end
  end
end
