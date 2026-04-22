# ICal

A library for reading and writing iCalendar data.

## Features

* Parsing iCalendar data from strings or files
* Serializing iCalendar data to iolists suitable for writing out to files, send over the network, etc.
* Integration with Plug / Phoenix via `ICal.encode_to_iodata`
* Components supported
  * Events (with alarms)
  * Todos (with alarms)
  * Journals
  * Timezones
  * Alarms
* Recurrence calculations
* Alarm calculations
* Compatibility
  * RFC 5545 compliant
  * Support for common non-standard properties, including:
      * `X-WR-TIMEZONE`
      * `X-WR-CALNAME`/`NAME`
  * Timezones are resolved using the system timezone library, supporting variants seen in the wild
  * All`X-*` fields and valid-by-not-yet-supported fields are retained

### Future work

Components that will eventually be supported (in rough order):

* Free/busy (VFREEBUSY)

## Usage

Full documentation can be found on [Hexdocs](https://hexdocs.pm/ical).

The primary entry points are `ICal.from_ics/1` and `ICal.from_file/1` for parsing iCalendar data,
and `ICal.to_ics/1` for serializing an `%ICal{}` to an `iodata` ready for writing to a file, sending
over the network, etc.

```elixir
calendar = ICal.from_file(ical_path)
%ICal{events: events} = calendar
ics_iodata = ICal.to_ics(calendar)
```

To accommodate applications which use `rrule` strings on their own, `ICal.Recurrence` structs can
be created these strings using `ICal.Recurrence.from_ics/1`:

```elixir
ICal.Recurrence.from_ics("RRULE:RRULE:FREQ=YEARLY;COUNT=10;BYMONTH=6,7")
```

Recurrence dates may be calculated from either a calendar component or a `%ICal.Recurrence{}` using
the `ICal.Recurrence.stream/2` function, while alarms may be resolved using `ICal.Alarm.next_alarms/1`.

Inline attachments can be decoded via `ICal.Attachment.decoded_data/1`.

## Installation

- Add `:ical` to your list of dependencies in `mix.exs`, along with a timezone database:

  ```elixir
  def deps do
    [
      {:ical, "~> 2.0"},
      {:tz, "~> 0.28"}
    ]
  end
  ```

  Then configure the timezone database in e.g. `config/config.exs`:

  ```elixir
  config :elixir, :time_zone_database, Tz.TimeZoneDatabase
  ```
  For auto-updating the timezone database at runtime, check the documentation for the timezone
  library you are using.

  The following timezone database packages are known to work well with ICal:

  | Package | Module |
  |---|---|
  | [`tz`](https://hex.pm/packages/tz) | `Tz.TimeZoneDatabase` |
  | [`time_zone_info`](https://hex.pm/packages/time_zone_info) | `TimeZoneInfo.TimeZoneDatabase` |

  See [tzdb_test](https://github.com/mathieuprog/tzdb_test) for more
  information on the available timezone database libraries.

## Goals

* corrrect: support the iCalendar (and its related) RFCs for standards-compliance
* useful: handle real-world data (such as produced by other clients) gracefully, do
  not lose data while parsing (including fields not supported by / used in this library)
* good developer experience
  * parsed results should be easy to use, even if iCalednar is a complex format
  * typed structs and clear APIs
  * good doucmentation
* resource friendly: be performant in parsing and serializing
* reliable: be well-tested, beyond just code coverage

## Participating in development

Visit the [issue tracker](https://github.com/expothecary/icalendar/issues) to see what
tasks are outstanding. You are welcome to file new issues, as well!

PRs are welcome and responded to in a timely fashion.

Benchee is used for benchmarking, credo for linting, and the test suite must pass before
PRs are merged. New functionality and bug fixes must have accompanying unit tests.
