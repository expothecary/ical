defmodule ICal.TodoTest do
  use ExUnit.Case

  alias ICal.Test.Fixtures
  alias ICal.Test.Helper

  test "Deserializing calendar with todos" do
    calendar =
      "todos"
      |> Helper.test_data()
      |> ICal.from_ics()

    assert Enum.count(calendar.todos) == 2

    Enum.each(calendar.todos, fn todo ->
      assert todo == Fixtures.todo(todo.uid)
    end)
  end

  test "Desierializing an empty buffer returns nil" do
    assert {"", nil} == ICal.Deserialize.Todo.one("", %ICal{})
    assert {"", nil} == ICal.Deserialize.Todo.one("\r\n", %ICal{})
    assert {"", nil} == ICal.Deserialize.Todo.one("\n", %ICal{})
  end

  test "Serializing a calendar with todos" do
  end
end
