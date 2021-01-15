# Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

- Fixed atom table exhaustion vulnerability by using `to_existing_atom` instead of `to_atom` when processing untrusted ICS files. ([#75](https://github.com/lpil/icalendar/pull/75) by @nixxquality)
- Support for arbitrary calendar headers via options (e.g., METHOD for RSVP buttons). ([#56](https://github.com/lpil/icalendar/pull/56) by @nickgartmann)
- Gmail compatibility: ORGANIZER field now uses semi-colon separator as required. ([#70](https://github.com/lpil/icalendar/pull/70) by @maedhr)
- Added RECURRENCE-ID support for identifying specific instances of recurring events (RFC 5545 Section 3.8.4.4).
- Add support for the `DTSTAMP` field.
  If not provided, it is initialized to the current UTC DateTime when serializing.

## v1.1.2 - 2022-01-16

- Handle calendars that wrap output such as Google Calendar

## v1.1.1 - 2021-12-26

- Fixed a bug where newlines were incorrectly handled.

## v1.1.0 - 2020-10-06

- The `ICalendar.Recurrence.get_recurrences` function has been added to enable
  calculation of recurring events from RRULE.

## v1.0.3 - 2020-08-19

- Calendars with empty lines in events are now parsed successfully.

## v1.0.2 - 2019-10-06

- Calendars with empty lines are now parsed successfully.

## v1.0.1 - 2019-09-17

- Empty parameter values in a VEVENT are now parsed successfully.

## v1.0.0 - 2019-09-05

- First stable release.
