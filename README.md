# ICal

A library for reading and writing iCalendar data.

## Features

* Parsing iCalendar data from strings or files
* Serializing iCalendar data to iolists suitable for writing out to files, over the network, etc.
* Integration with Plug / Phoenix via `ICal.encode_to_iodate`
* Recurrence calculation
* Support for common non-standard entries such as `X-WR-TIMEZONE`

### Usage

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

* support the iCalendar (and its related) RFCs for standards-compliance
* handle real-world data (such as produced by other clients) gracefully, and
  not lose data while parsing, even if not used by this library
* be performant in parsing and serializing
* be well-documented
* be well-tested (beyond just code coverage)

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
