# Grapexir
GrapeXir leverages historical climate data to provide actionable insights for winemakers, helping them identify the best regions and seasons for grape cultivation.

# Run the seed data to populate the regions in the Databse
`mix run priv/repo/seeds.exs`

# Validate Typespecs
`mix dialyzer`

# Running tests
For all tests: `mix test`
For individual tests: `mix test apps/data_ingestion/test/data_ingestion/service_test.exs`

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `grapexir` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:grapexir, "~> 0.1.0"}
  ]
end
```

## Fetching data

```
# P.S This is a MVP version without a cron job running a daily worker to process all the regions
regions = Repo.all(Grapexir.Region)
Enum.each(fn region -> Worker.perform(%{args: %{"region_id" => region.id}}) end)
```


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/grapexir>.

