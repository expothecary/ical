defmodule ICal.JournalTest do
  use ExUnit.Case

  alias ICal.Test.Fixtures
  use ICal.Test.Helper

  test "Deserializing calendar with journals" do
    calendar =
      "journals"
      |> Helper.test_data()
      |> ICal.from_ics()

    assert Enum.count(calendar.journals) == 1

    Enum.each(calendar.journals, fn journal ->
      assert journal == Fixtures.journal(journal.uid)
    end)
  end

  test "Desierializing an empty buffer returns nil" do
    assert {"", nil} == ICal.Deserialize.Journal.one("", %ICal{})
    assert {"", nil} == ICal.Deserialize.Journal.one("\r\n", %ICal{})
    assert {"", nil} == ICal.Deserialize.Journal.one("\n", %ICal{})
  end

  test "Serializing a calendar with journals" do
    expected = Helper.test_data("journals")

    %ICal{
      journals: [
        Fixtures.journal("19970901T130000Z-123405@example.com")
      ]
    }
    |> ICal.to_ics()
    |> assert_fully_contains(expected)
  end
end
