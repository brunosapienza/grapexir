defmodule DataIngestionTest do
  use ExUnit.Case
  doctest DataIngestion

  test "greets the world" do
    assert DataIngestion.hello() == :world
  end
end
