# ICal

A library for reading and writing iCalendar data.

## Features

* Parsing iCalendar data from strings or files
* Serializing iCalendar data to iolists suitable for writing out to files, send over the network, etc.
* Integration with Plug / Phoenix via `ICal.encode_to_iodata`
* Components supported
  * Events (with alarms)
  * Alarms
* Recurrence calculations (currrently only `BYDAY` is supported)
* Compatibility
  * RFC 5545 compliant
  * Support for common non-standard properties, including:
      * `X-WR-TIMEZONE`
      * `X-WR-CALNAME`/`NAME`
  * Timezones are resolved using the system timezone library, supporting variants seen in the wild
  * All`X-*` fields and valid-by-not-yet-supported fields are retained

### Future work

Components that will eventually be supported (in rough order):

* Timezone (VTIMEZONE)
* Free/busy (VFREEBUSY)
* Todos (VTODO)
* Journals (VJOURNAL)

Planned features:

* Alarm calculation
* Expanded recurrency calculation

## Usage

Full documentation can be found on [Hexdocs](https://hexdocs.pm/ical).

The primary entry points are `ICal.from_ics/1` and `ICal.from_file/1` for parsing iCalendar data,
and `ICal.to_ics/1` for serializing an `%ICal{}` to an `iodata` ready for writing to a file, sending
over the network, etc.

Individual calendar entries (e.g. `%ICal.Event{}`) can also be de/serialized via their respective
modules.

```elixir
calendar = ICal.from_file(ical_path)
%ICal{events: events} = calendar
ics_iodata = ICal.to_ics(calendar)
```

Recurrences may be calculated from a calendar component up to a given future date:

```elixir
  reccurences =
    event
    |> ICalendar.Recurrence.get_recurrences(~U[2027-01-01 00:00:00Z])
    |> Enum.take(4)
```

Inline attachments can be decoded via `ICal.Attachment.decoded_data/1`.

## Goals

* corrrect: support the iCalendar (and its related) RFCs for standards-compliance
* useful: handle real-world data (such as produced by other clients) gracefully, do
  not lose data while parsing (including fields not supported by / used in this library)
* good DevExp
  * parsed results should be easy to use, even if iCalednar is a complex format
  * typed structs and clear APIs
  * good doucmentation
* resource friendly: be performant in parsing and serializing
* reliable: be well-tested, beyond just code coverage

## Installation

The package can be installed by adding `:ical` to your list of dependencies
in `mix.exs`:

```elixir
def deps do
  [
    {:ical, "~> 1.0"}
  ]
end
```

## Participating in develpoment

Visit the [issue tracker](https://github.com/expothecary/icalendar/issues) to see what
tasks are outstanding. You are welcome to file new issues, as well!

PRs are welcome and responded to in a timely fashion.

Benchee is used for benchmarking, credo for linting, and the test suite must pass before
PRs are merged. New functionality and bug fixes must have accompanying unit tests.
