# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Grapexir.Repo.insert!(%Grapexir.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Grapexir.Repo
alias Grapexir.Region

regions = [
  %Region{ name: "McLaren Vale, South Australia", latitude: -35.22, longitude: 138.54 },
  %Region{ name: "Margaret River, Western Australia", latitude: -33.96, longitude: 115.08 },
  %Region{ name: "Mornington, Victoria", latitude: -38.22, longitude: 145.04 },
  %Region{ name: "Coonawarra, South Australia", latitude: -37.29, longitude: 140.83 },
  %Region{ name: "Yarra Valley, Victoria", latitude: -37.75, longitude: 145.10 }
]

Enum.each(regions, fn region -> Repo.insert(region) end)
