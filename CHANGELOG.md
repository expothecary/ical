# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
