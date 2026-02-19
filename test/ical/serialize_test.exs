defmodule ICal.SerializeTest do
  use ExUnit.Case

  alias ICal.Serialize

  test "Serializing parameters lists" do
    params = %{
      "X-1" => %{params: %{"P" => "1", "P2" => "2"}, value: "a"},
      "X-2" => %{params: %{"P3" => "3", "P4" => "4"}, value: "b"},
      "X-3" => "garbage"
    }

    serialized = Serialize.add_custom_properties([], params) |> to_string()

    assert String.contains?(serialized, "X-1;P=1;P2=2:a\n")
    assert String.contains?(serialized, "X-2;P3=3;P4=4:b\n")
  end
end
