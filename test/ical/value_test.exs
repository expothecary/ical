defmodule ICal.ValueTest do
  use ExUnit.Case

  alias ICal.Serialize

  test "value of a date" do
    result = Serialize.value(Timex.to_date({2016, 1, 4}))
    assert result == "20160104"
  end

  test "value of a datetime" do
    result = Serialize.value(Timex.to_datetime({{2016, 1, 4}, {0, 42, 23}}))
    assert result == "20160104T004223Z"
  end

  test "value of a datetime tuple" do
    result = Serialize.value({{2016, 1, 4}, {0, 42, 23}})
    assert result == "20160104T004223Z"
  end

  test "value of a nearly datetime tuple" do
    result = Serialize.value({{2016, 13, 4}, {0, 42, 23}})
    assert result == {{2016, 13, 4}, {0, 42, 23}}
  end

  test "value of an integer" do
    result = Serialize.value(42)
    assert result == "42"
  end

  test "value of a float" do
    result = Serialize.value(3.14159)
    assert result == "3.14159"
  end

  test "value of a very different type" do
    result = Serialize.value({:ok, "Hi there"})
    assert result == {:ok, "Hi there"}
  end

  test "value of a string with newline" do
    result =
      Serialize.value("""
      Hello
      World!
      """)

    assert result == ~S"Hello\nWorld!\n"
  end

  test "value of a string with newline like chars" do
    result = Serialize.value(~S"Hi\nthere")
    assert result == ~S"Hi\\nthere"
  end

  test "value of a string with comma, backslash, and semicolon chars" do
    result = Serialize.value(~S"Comma is , backslash \ with ; semicolon")
    assert result == ~S"Comma is \, backslash \\ with \; semicolon"
  end
end
