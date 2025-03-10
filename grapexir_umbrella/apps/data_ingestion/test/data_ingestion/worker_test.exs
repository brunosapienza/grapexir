defmodule Grapexir.DataIngestion.WorkerTest do
  use Grapexir.DataCase, async: true

  alias Grapexir.DataIngestion.Worker
  alias Grapexir.{Repo, Region}

  setup do
    today = ~D[2025-03-10]
    region = %Region{id: 1, name: "Melbourne", latitude: -37.8136, longitude: 144.9631} |> Repo.insert!()

    {:ok, today: today, region: region}
  end

  defmodule MockService do
    def fetch_region(_id), do: {:ok, %Region{id: 1, name: "Melbourne", latitude: -37.8136, longitude: 144.9631}}
    def get_date_range(_id, _lookback_days), do: {~D[2025-01-01], ~D[2025-03-10]}
    def fetch_climate_data(_, _, _), do: {:ok, "{ \"mocked\": \"climate data\" }"}
    def create_climate_records(_), do: {:ok, "Data ingestion completed"}
  end

  defmodule MockParser do
    def parse_and_build_changesets(_, _), do: {:ok, []}
  end

  describe "perform/1" do
    test "successfully performs data ingestion", %{region: region} do
      assert Worker.perform(%{args: %{"region_id" => region.id}}, MockService, MockParser) == {:ok, "Data ingestion completed"}
    end

    test "fails when region does not exist" do
      defmodule MockFailingServiceRegionNotFound do
        def fetch_region(_), do: {:error, "Region not found"}
      end

      assert Worker.perform(%{args: %{"region_id" => 99}}, MockFailingServiceRegionNotFound, MockParser) == {:error, "Region not found"}
    end

    test "fails when climate data fetching fails" do
      defmodule MockFailingServiceDataError do
        def fetch_region(_), do: {:ok, %Region{id: 2, name: "Sydney", latitude: -33.8688, longitude: 151.2093}}
        def get_date_range(_, _), do: {~D[2025-01-01], ~D[2025-03-10]}
        def fetch_climate_data(_, _, _), do: {:error, "API error"}
      end

      assert Worker.perform(%{args: %{"region_id" => 2}}, MockFailingServiceDataError, MockParser) == {:error, "API error"}
    end
  end
end
