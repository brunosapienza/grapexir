defmodule Grapexir.DataIngestion.ParserTest do
  use ExUnit.Case, async: true
  alias Grapexir.DataIngestion.Parser

  describe "parse_and_build_changesets/2" do
    test "parses valid JSON and returns a list of valid changesets" do
      body = ~s({"daily": {"time": ["2025-03-01", "2025-03-02"], "temperature": [30, 32]}})
      region_id = 1

      assert {:ok, changeset_stream} = Parser.parse_and_build_changesets(body, region_id)

      changesets = Enum.to_list(changeset_stream)

      assert Enum.all?(changesets, fn cs -> cs.valid? end)
      assert length(changesets) == 2
      assert Enum.at(changesets, 0).changes == %{date: ~D[2025-03-01], temperature_model: "temperature", max_temperature: 30, region_id: 1}
      assert Enum.at(changesets, 1).changes == %{date: ~D[2025-03-02], temperature_model: "temperature", max_temperature: 32, region_id: 1}
    end

    test "returns an error when given invalid JSON" do
      body = "invalid json"
      region_id = 1

      assert {:error, _} = Parser.parse_and_build_changesets(body, region_id)
    end
  end
end
