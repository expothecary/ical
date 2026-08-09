# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

- Features
  - Availability (`VAVAILABILITY`) and its `AVAILABLE` subcomponents are now
    deserialized and serialized, implementing
    [RFC 7953](https://www.rfc-editor.org/rfc/rfc7953.html). Components are
    collected on `ICal.availabilities` as `%ICal.Availability{}` structs, each
    holding `%ICal.Availability.Available{}` subcomponents in `available`.
  - The `BUSYTYPE` property is parsed to `:busy`, `:busy_unavailable` or
    `:busy_tentative`, defaulting to `:busy_unavailable` as RFC 7953 requires.
    IANA and vendor tokens are retained verbatim.

## v3.1.1

- Fixes
  - UNTIL dates in RRULEs are no long timezone-shifted. In most cases this makes no difference,
    but in some edge cases it does. The RFC itself gets this wrong in one of its examples,
    but the consensus among implementations appears to be this.
- Janitorial
  - Update dependences

## v3.1.0

Small but important improvements in RFC compliance with regards to floating dates and
date-only recurrences.

- Improvements
  - Support for "floating dates" (NaiveDateTime) in RRULEs
  - Match RRULE date/time types to the starting date when generating recurrences
  - More tests for recurrence parsing/serialization added
- Fixes
  - Dates are now supported in RRULE UNTIL field (previously only DateTimes were)

## v3.0.0

A major version bump due to adding support for floating dates, which causes some functions to
now return `NaiveDateTime`s (aka "floating date/times") in addition to `Date`s and `DateTime`s.

- Improvements
  - Support floating date/times, the ICalendar equivalent of NaiveDateTime
  - Added types in ICal module for dates and datetimes; more consistent, less verbose, easier to read
- Fixes
  - Unrecognized components could be incorrectly parsed due to a missing variable pin in gather_unrecognized_component
- Janitorial
  - Removed some unused imports/requires
  - Small improvements to test suites

Contributors to this release include:

- [Girish Gopaul](https://github.com/giriss)

## v2.0.2

- Fixes
  - Fix deserialization of paramerter lists that span multiple lines

## v2.0.1

- Improvements
  - When a timezone database is not available, an error logged warning that ICal will not work correctly.
    Even better, ICal will register a timezone database if either the `Tz` or `TimeZoneInfo` libraries are
    available, and will issue an info-level log message about this. Hopefully fewer people will run into
    issues from not having a timezone db setup as a result.
- Fixes
  - Properties of type `DATE` which also have a timezone defined on them now parse correctly. While such
    data is probably not RFC-compliant, there are clients/libraries in the wild that produce such entries,
    and ICal now produces the expected results. Conservative in what you send, liberal in what you receive,
    as they say.

## v2.0.0

The minimum version of Elixir required is 1.17. Support for Elixir 1.15 and 1.16 was
dropped so `ICal` may use the improved date and calendaring APIs introduced in 1.17.

It is recommended to add a timezone database such as `tz` to applications that use
ICal in order to benefit fully from these changes.

- Improvements
  - Recurrence generation was re-written and is now feature complete
    - The entirety of the RFC5545 RRULE specification is supported
    - Works with `ICal.Event`, `ICal.Todo` and `ICal.Journal`
    - Recurrence dates (`RDATE`) are included
    - Excluded dates (`EXDATE`) are respected
  - New functions in `ICal.Alarm`
    - `next_activation/2`: calculates when an alarm should next activate (if ever)
    - `next_alarms/1`: returns all next alarms with activation times for a compoonent with
      alarms (`ICal.Event`, `ICal.Todo`)
- Fixes
  - Gap and ambiguous times are properly handled when a datetime lands in a timezone shift period
  - Properly parse lists of excluded dates
  - Fix serializing of components with status of draft
- Janitorial
  - The dependency on `Timex` was removed
  - Documentation improvements

Contributors to this release include:
- [Matthew Lehner](https://github.com/matthewlehner)
- [Patrick Wendo](https://github.com/W3NDO)

## v1.1.2
- Fixes
  - Fix parsing of Timezones and unknown components with CR/LF line endings

## v1.1.1
- Fixes
  - Fix parsing ICal files with CR/LF line endings (@pedrogarrett)
  - Support "line folding" multiline entries as per the RFC for all line entries

## v1.1.0

- Improvements
  - `ICal.Timezone`: a struct that represents `VTIMEZONE` calendar components
  - `ICal.Todo`: a struct that represents `VTODO` calendar components
  - `ICal.Journal`: a struct that represents `VJOURNAL` calendar components
  - `ICal.RequestStatus`: a struct that represents the `rstatus`, or request status, of a component
    - Added request status support to `ICal.Event`
  - Dates with local times are represented with `NaiveDateTime`s
  - Arbitrary lists of components can be serialized with `ICal.to_ics` without being in an `%ICal{}`
- Fixes
  - `ICal.Deserialize.to_integer` wraps integer parsing for safety in more cases
  - Correct placement of the `:` separator in custom properties with parameters
  - Preserve `priority` and `sequence` properties
  - Parse dates in ICS as Elixir `Date`s, rather than "upgrade" them to `DateTime`s
- Janitorial
  - Improved documentation layout
  - More unit tests

## v1.0.0

- First public release.
- Forked from the Elixir ICalendar library with extensive fixes including:
  - Fixed atom table exhaustion vulnerability by using `to_existing_atom` instead of `to_atom` when processing untrusted ICS files. ([#75](https://github.com/lpil/icalendar/pull/75) by @nixxquality)
  - Support for arbitrary calendar headers via options (e.g., METHOD for RSVP buttons). ([#56](https://github.com/lpil/icalendar/pull/56) by @nickgartmann)
  - Gmail compatibility: ORGANIZER field now uses semi-colon separator as required. ([#70](https://github.com/lpil/icalendar/pull/70) by @maedhr)
  - Added RECURRENCE-ID support for identifying specific instances of recurring events (RFC 5545 Section 3.8.4.4).
  - Add support for the `DTSTAMP` field in events.
    - If not provided, it is initialized to the current UTC DateTime when serializing.
  - Add support for multiple comments in events. The `comment` fields is now `comments` and is an array
  - `to_ics` returns iolists. This prevents unecessary (and slower) string creation when the common use case is to send the data into a file, across a socket, etc. which all consume ioslists natively.
  - Deserialization now produces a Calendar struct
  - Calendar structs contain calendar metadata, such as the ical version, the product id, and method
    - These same fields are serialized out, and this replaces the `options` parameter in `to_ics`
  - Many fixes around serialization/deserialization when it came to escaping and parsing escaped entries, lists, and parameters
- Expanded test suite, with fixtures and ics data in files
