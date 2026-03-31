defmodule ICal.TodoTest do
  use ExUnit.Case

  alias ICal.Test.Fixtures
  use ICal.Test.Helper

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
    expected = Helper.test_data("todos")

    %ICal{
      todos: [
        Fixtures.todo("20070514T103211Z-123404@example.com"),
        Fixtures.todo("20070313T123432Z-456553@example.com")
      ]
    }
    |> ICal.to_ics()
    |> assert_fully_contains(expected)
  end

  @tag :skip
  test "next_alarm/1 for a todo with recurrences" do
    todo_with_alarm = Fixtures.todo(:one_alarm)

    actual_next_alarms = ICal.Todo.next_alarms(todo_with_alarm)
    expected_next_alarm = Fixtures.alarm(:audio)
    assert [expected_next_alarm] == actual_next_alarms
  end

  test "next_alarm/1 for a todo with no alarm" do
    todo_without_alarm = Fixtures.todo("20070313T123432Z-456553@example.com")

    actual_next_alarms = ICal.Todo.next_alarms(todo_without_alarm)
    assert [] == actual_next_alarms
  end

  test "next_alarm/1 for a todo with no recurrences, but occurs in future" do
    todo_without_recurrences = Fixtures.todo(:future_no_recurrences)

    actual_next_alarms = ICal.Todo.next_alarms(todo_without_recurrences)
    expected_next_alarms = Fixtures.alarm(:audio)

    assert [expected_next_alarms] == actual_next_alarms
  end
end
