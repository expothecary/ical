# ICal

A library for reading and writing iCalendar data.

## Features

Full documentation can be found on [Hexdocs](https://hexdocs.pm/ical).

* Parsing iCalendar data from strings or files
* Serializing iCalendar data to iolists suitable for writing out to files, over the network, etc.
* Integration with Plug / Phoenix via `ICal.encode_to_iodate`
* Support for common non-standard entries such as `X-WR-TIMEZONE`

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
