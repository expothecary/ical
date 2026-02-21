defmodule ICal.Test.Fixtures do
  @moduledoc false

  def iodata_calendar do
    %ICal{
      events: [
        %ICal.Event{
          summary: "Film with Amy and Adam",
          dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 00}}),
          dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
          description: "Let's go see Star Wars."
        },
        %ICal.Event{
          summary: "Morning meeting",
          dtstart: Timex.to_datetime({{2015, 12, 24}, {19, 00, 00}}),
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {18, 00, 00}}),
          dtend: Timex.to_datetime({{2015, 12, 24}, {22, 30, 00}}),
          description: "A big long meeting with lots of details."
        }
      ]
    }
  end

  def one_event(which \\ :deserialize)

  def one_event(:serialize) do
    %ICal.Event{
      summary: "Going fishing",
      description: "Escape from the world. Stare at some water.",
      comments: ["Don't forget to take something to eat !"],
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
      created: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
      contacts: [
        %ICal.Contact{
          alternative_representation:
            "ldap:ldap://example.com:6666/o=ABC% 20Industries,c=US???(cn=Beat%20Fuss)",
          language: "de",
          value: "Beat Fuss"
        },
        %ICal.Contact{value: "Jill Bar"}
      ],
      priority: "",
      attachments: [
        %ICal.Attachment{
          data_type: :cid,
          data: "jsmith.part3.960817T083000.xyzMail@example.com",
          mimetype: nil
        },
        %ICal.Attachment{
          data_type: :uri,
          data: "ftp://example.com/pub/reports/r-960812.ps",
          mimetype: "application/postscript"
        },
        %ICal.Attachment{
          data_type: :base8,
          data: "Some plain text",
          mimetype: nil
        },
        %ICal.Attachment{
          data_type: :base64,
          data: "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZy4",
          mimetype: "text/plain"
        },
        %ICal.Attachment{
          data_type: :base64,
          data:
            "TG9yZW0gaXBzdW0gZG9sb3Igc2l0IGFtZXQsIGNvbnNlY3RldHVyIGFkaXBpc2ljaW5nIGVsaXQsIHNlZCBkbyBlaXVzbW9kIHRlbXBvciBpbmNpZGlkdW50IHV0IGxhYm9yZSBldCBkb2xvcmUgbWFnbmEgYWxpcXVhLiBVdCBlbmltIGFkIG1pbmltIHZlbmlhbSwgcXVpcyBub3N0cnVkIGV4ZXJjaXRhdGlvbiB1bGxhbWNvIGxhYm9yaXMgbmlzaSB1dCBhbGlxdWlwIGV4IGVhIGNvbW1vZG8gY29uc2VxdWF0LiBEdWlzIGF1dGUgaXJ1cmUgZG9sb3IgaW4gcmVwcmVoZW5kZXJpdCBpbiB2b2x1cHRhdGUgdmVsaXQgZXNzZSBjaWxsdW0gZG9sb3JlIGV1IGZ1Z2lhdCBudWxsYSBwYXJpYXR1ci4gRXhjZXB0ZXVyIHNpbnQgb2NjYWVjYXQgY3VwaWRhdGF0IG5vbiBwcm9pZGVudCwgc3VudCBpbiBjdWxwYSBxdWkgb2ZmaWNpYSBkZXNlcnVudCBtb2xsaXQgYW5pbSBpZCBlc3QgbGFib3J1bS4=",
          mimetype: "text/plain"
        }
      ],
      resources: ["one", "two", "three"],
      related_to: ["jsmith.part7.19960817T083000.xyzMail@example.com", "other"],
      transparency: :opaque
    }
  end

  def one_event(:deserialize) do
    %ICal.Event{
      dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 0}}),
      dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 0}}),
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}}),
      summary: "Going fishing",
      description: "Escape from the world. Stare at some water.",
      location: "123 Fun Street, Toronto ON, Canada",
      status: :tentative,
      categories: ["Fishing", "Nature"],
      comments: ["Don't forget to take something to eat !"],
      contacts: [
        %ICal.Contact{
          alternative_representation:
            "ldap:ldap://example.com:6666/o=ABC% 20Industries,c=US???(cn=Beat%20Fuss)",
          language: "de",
          value: "Beat Fuss"
        },
        %ICal.Contact{value: "Jill Bar"}
      ],
      created: ~U[1996-03-29 13:30:00Z],
      class: "PRIVATE",
      duration: %ICal.Duration{
        days: 15,
        positive: true,
        time: {5, 0, 20},
        weeks: 0
      },
      geo: {43.6978819, -79.3810277},
      modified: ~U[1996-08-17 13:30:00Z],
      organizer: "mailto:jsmith@example.com",
      priority: 2,
      related_to: ["jsmith.part7.19960817T083000.xyzMail@example.com"],
      resources: ["EASEL", "PROJECTOR", "VCR"],
      sequence: 1000,
      uid: "1001"
    }
  end

  def uid_only_event do
    %ICal.Event{
      uid: "YES",
      comments: ["Should appear normally"]
    }
  end

  def transparencies do
    %ICal{
      events: [
        %ICal.Event{
          uid: "1",
          transparency: :transparent
        },
        %ICal.Event{
          uid: "2",
          transparency: :opaque
        },
        %ICal.Event{
          uid: "3",
          transparency: nil
        }
      ]
    }
  end

  def rdates do
    %ICal{
      events: [
        %ICal.Event{
          uid: "1",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}}),
          rdates: [
            ~U[1997-01-01 00:00:00Z],
            ~U[1997-01-20 00:00:00Z],
            ~U[1997-02-17 00:00:00Z],
            ~U[1997-04-21 00:00:00Z],
            DateTime.from_naive!(~N[2018-05-24 13:26:08], "Europe/Zurich")
          ]
        },
        %ICal.Event{
          uid: "2",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}}),
          rdates: [
            ~U[1997-01-01 00:00:00Z],
            ~U[1997-01-20 00:00:00Z],
            ~U[1997-02-17 00:00:00Z],
            ~U[1997-04-21 00:00:00Z]
          ]
        },
        %ICal.Event{
          uid: "3",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}}),
          rdates: [
            {~U[1997-01-01 18:00:00Z], ~U[1997-01-02 07:00:00Z]},
            {~U[1998-01-01 18:00:00Z], ~U[1998-01-02 07:00:00Z]},
            {~U[1999-01-01 18:00:00Z],
             %ICal.Duration{positive: true, time: {0, 0, 0}, days: 0, weeks: 2}}
          ]
        },
        %ICal.Event{
          uid: "4",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICal.Event{
          uid: "5",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICal.Event{
          uid: "6",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICal.Event{
          uid: "7",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        }
      ]
    }
  end

  def contacts do
    %ICal{
      events: [
        %ICal.Event{
          uid: "1",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}}),
          contacts: [
            %ICal.Contact{
              alternative_representation: "CID:part3.msg970930T083000SILVER@example.com",
              value: "Jim Dolittle, ABC Industries, +1-919-555-1234"
            },
            %ICal.Contact{value: "Joe Blow"},
            %ICal.Contact{
              language: "de",
              value: "Beat Fuss"
            },
            %ICal.Contact{
              alternative_representation:
                "ldap:ldap://example.com:6666/o=ABC% 20Industries,c=US???(cn=Beat%20Fuss)",
              language: "de",
              value: "Beat Fuss"
            }
          ]
        }
      ]
    }
  end

  def statuses(which \\ :deserialize)

  def statuses(:deserialize) do
    %ICal{
      events: [
        %ICal.Event{
          uid: "1",
          status: :tentative,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICal.Event{
          uid: "2",
          status: :confirmed,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICal.Event{
          uid: "3",
          status: :cancelled,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICal.Event{
          uid: "4",
          status: nil,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        }
      ]
    }
  end

  def statuses(:serialize) do
    %ICal{
      events: [
        %ICal.Event{
          uid: "1",
          status: :tentative,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICal.Event{
          uid: "2",
          status: :confirmed,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICal.Event{
          uid: "3",
          status: :cancelled,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICal.Event{
          uid: "4",
          status: nil,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICal.Event{
          uid: "5",
          status: "CUSTOM",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        }
      ]
    }
  end

  def one_truncated_event do
    %ICal.Event{
      dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 0}}),
      dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 0}}),
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}}),
      summary: "Going fishing",
      description: "Escape from the world. Stare at some water.",
      location: "123 Fun Street, Toronto ON, Canada",
      status: :tentative,
      categories: ["Fishing", "Nature"],
      comments: ["Don't forget to take something to eat !"],
      contacts: [
        %ICal.Contact{
          value: "Jim Dolittle, ABC Industries, +1-919-555-1234",
          alternative_representation: "CID:part3.msg970930T083000SILVER@example.com"
        }
      ],
      class: "PRIVATE",
      geo: {43.6978819, -79.3810277},
      resources: ["Nettoyeur haute pression"]
    }
  end

  def broken_dates_event do
    %ICal.Event{
      dtstart: nil,
      dtend: nil,
      dtstamp: nil,
      created: nil,
      exdates: [],
      uid: "1"
    }
  end

  def calendar(:empty) do
    %ICal{
      product_id: "-//Elixir ICal//EN",
      scale: "GREGORIAN",
      method: "REQUEST",
      version: "2.0"
    }
  end

  def calendar(:custom_properties) do
    %ICal{
      product_id: "-//Elixir ICal//EN",
      scale: "GREGORIAN",
      method: "REQUEST",
      version: "2.0",
      default_timezone: "Europe/Zurich",
      custom_properties: %{
        "X-CUSTOM-THREE" => %{params: %{}, value: "BAZ"},
        "X-CUSTOM-TWO" => %{params: %{}, value: "Cat"},
        "X-CUSTOM" => %{params: %{"FOO" => "bar"}, value: "Door"},
        "X-WR-TIMEZONE" => %{params: %{}, value: "Europe/Zurich"}
      },
      events: [
        %ICal.Event{
          uid: "1",
          custom_properties: %{"X-CUSTOM" => %{params: %{}, value: "value"}}
        }
      ]
    }
  end

  def attendees do
    %ICal{
      product_id: "-//Elixir ICal//EN",
      scale: "GREGORIAN",
      method: nil,
      version: "2.0",
      events: [
        %ICal.Event{
          uid: "01",
          created: nil,
          dtstart: nil,
          dtend: nil,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 00}}),
          modified: nil,
          recurrence_id: nil,
          exdates: [],
          rdates: [],
          rrule: nil,
          class: nil,
          description: "An event with attendees",
          duration: nil,
          location: nil,
          status: nil,
          organizer: nil,
          sequence: nil,
          summary: nil,
          url: nil,
          geo: nil,
          priority: nil,
          transparency: nil,
          attendees: [
            %ICal.Attendee{
              name: "mailto:janedoe@example.com",
              language: nil,
              type: nil,
              membership: ["mailto:projectA@example.com", "mailto:projectB@example.com"],
              role: "CHAIR",
              status: nil,
              rsvp: false,
              delegated_to: ["mailto:jdoe@example.com", "mailto:jqpublic@example.com"],
              delegated_from: [],
              sent_by: nil,
              cname: nil,
              dir: nil
            },
            %ICal.Attendee{
              name: "mailto:jdoe@example.com",
              language: nil,
              type: nil,
              membership: [],
              role: nil,
              status: nil,
              rsvp: true,
              delegated_to: [],
              delegated_from: ["mailto:jsmith@example.com"],
              sent_by: nil,
              cname: nil,
              dir: nil
            },
            %ICal.Attendee{
              name: "mailto:ietf-calsch@example.org",
              language: "de-ch",
              type: "GROUP",
              membership: [],
              role: nil,
              status: "ACCEPTED",
              rsvp: false,
              delegated_to: [],
              delegated_from: [],
              sent_by: "mailto:sray@example.com",
              cname: "John Smith",
              dir: "ldap://example.com:6666/o=ABC%20Industries,c=US???(cn=Jim%20Dolittle)"
            }
          ],
          attachments: [],
          categories: [],
          comments: [],
          contacts: [],
          related_to: [],
          resources: []
        }
      ]
    }
  end

  def recurrence_event do
    %ICal{
      version: "2.0",
      events: [
        %ICal.Event{
          uid: "1",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
          dtend: Timex.to_datetime({{2015, 12, 24}, {12, 45, 00}}),
          created: Timex.to_datetime({{2015, 11, 24}, {8, 45, 00}}),
          rrule: %ICal.Recurrence{
            until: Timex.to_datetime({{2019, 11, 24}, {8, 45, 00}}),
            count: 3,
            by_second: [1],
            by_minute: [2],
            by_hour: [3],
            by_day: [{0, :wednesday}, {1, :friday}, {-2, :saturday}],
            by_month_day: [6],
            by_year_day: [7, 8, 9],
            by_month: [10],
            by_set_position: [20],
            by_week_number: [-1],
            weekday: :monday,
            frequency: :daily,
            interval: 1
          }
        }
      ],
      default_timezone: "Etc/UTC"
    }
  end

  def alarm(:audio) do
    %ICal.Alarm{
      action: %ICal.Alarm.Audio{
        attachments: [
          %ICal.Attachment{
            data_type: :uri,
            data: "ftp://example.com/pub/sounds/bell-01.aud",
            mimetype: "audio/basic"
          }
        ],
        duration: %ICal.Duration{days: 0, positive: true, time: {0, 15, 0}, weeks: 0},
        repeat: 0
      },
      custom_properties: %{},
      trigger: %ICal.Alarm.Trigger{
        relative_to: nil,
        repeat: 4,
        on: ~U[1997-03-17 13:30:00Z]
      }
    }
  end

  def alarm(:audio_no_duration) do
    %ICal.Alarm{
      action: %ICal.Alarm.Audio{
        attachments: [
          %ICal.Attachment{
            data_type: :uri,
            data: "ftp://example.com/pub/sounds/bell-01.aud",
            mimetype: "audio/basic"
          }
        ],
        repeat: 0
      },
      custom_properties: %{},
      trigger: %ICal.Alarm.Trigger{
        relative_to: nil,
        repeat: 4,
        on: ~U[1997-03-17 13:30:00Z]
      }
    }
  end

  def alarm(:display) do
    %ICal.Alarm{
      action: %ICal.Alarm.Display{
        description: "Breakfast meeting with executive\nteam at 8:30 AM EST.",
        duration: %ICal.Duration{days: 0, positive: true, time: {0, 15, 0}, weeks: 0}
      },
      custom_properties: %{},
      trigger: %ICal.Alarm.Trigger{
        relative_to: nil,
        repeat: 2,
        on: %ICal.Duration{positive: false, time: {0, 30, 0}, days: 0, weeks: 0}
      }
    }
  end

  def alarm(:display_start) do
    %ICal.Alarm{
      action: %ICal.Alarm.Display{
        description: "BOINK",
        duration: nil
      },
      custom_properties: %{"X-Extra" => %{params: %{}, value: "Yep"}},
      trigger: %ICal.Alarm.Trigger{
        relative_to: :start,
        repeat: 0,
        on: %ICal.Duration{positive: true, time: {0, 0, 0}, days: 2, weeks: 0}
      }
    }
  end

  def alarm(:email) do
    %ICal.Alarm{
      action: %ICal.Alarm.Email{
        attachments: [
          %ICal.Attachment{
            data_type: :uri,
            data: "http://example.com/templates/agenda.doc",
            mimetype: "application/msword"
          }
        ],
        attendees: [
          %ICal.Attendee{
            name: "mailto:john_doe@example.com",
            language: nil,
            type: nil,
            membership: [],
            role: nil,
            status: nil,
            rsvp: false,
            delegated_to: [],
            delegated_from: [],
            sent_by: nil,
            cname: nil,
            dir: nil
          }
        ],
        description:
          "A draft agenda needs to be sent out to the attendees to the weekly managers meeting (MGR-LIST). Attached is a pointer the document template for the agenda file.",
        summary: "*** REMINDER: SEND AGENDA FOR WEEKLY STAFF MEETING ***"
      },
      custom_properties: %{},
      trigger: %ICal.Alarm.Trigger{
        on: %ICal.Duration{
          days: 2,
          positive: false,
          time: {0, 0, 0},
          weeks: 0
        },
        relative_to: :end,
        repeat: 0
      }
    }
  end

  def alarm(:custom) do
    %ICal.Alarm{
      action: %ICal.Alarm.Custom{properties: %{}, type: "SomethingUnique"},
      custom_properties: %{attachments: [], attendees: []},
      trigger: %ICal.Alarm.Trigger{on: nil, relative_to: nil, repeat: 0}
    }
  end

  def todo("20070514T103211Z-123404@example.com") do
    %ICal.Todo{
      alarms: [],
      attachments: [],
      attendees: [],
      categories: [],
      class: nil,
      comments: [],
      completed: ~U[2007-07-07 10:00:00Z],
      contacts: [],
      created: nil,
      custom_properties: %{},
      description: nil,
      dtstamp: ~U[2007-05-14 10:32:11Z],
      dtstart: ~U[2007-05-14 11:00:00Z],
      due: ~U[2007-07-09 13:00:00Z],
      duration: nil,
      exdates: [],
      geo: nil,
      location: nil,
      modified: nil,
      organizer: nil,
      percent_completed: 0,
      priority: 1,
      rdates: [],
      recurrance_id: nil,
      related_to: [],
      request_status: [],
      resources: [],
      rrule: nil,
      sequence: 0,
      status: nil,
      summary: "Submit Revised Internet-Draft",
      uid: "20070514T103211Z-123404@example.com",
      url: nil
    }
  end

  def todo("20070313T123432Z-456553@example.com") do
    %ICal.Todo{
      alarms: [],
      attachments: [],
      attendees: [],
      categories: ["FAMILY", "FINANCE"],
      class: "CONFIDENTIAL",
      comments: [],
      completed: nil,
      contacts: [],
      created: nil,
      custom_properties: %{},
      description: nil,
      dtstamp: ~U[2007-03-13 12:34:32Z],
      dtstart: nil,
      due: ~U[2007-05-01 00:00:00Z],
      duration: nil,
      exdates: [],
      geo: nil,
      location: nil,
      modified: nil,
      organizer: nil,
      percent_completed: 0,
      priority: 0,
      rdates: [],
      recurrance_id: nil,
      related_to: [],
      request_status: [],
      resources: [],
      rrule: nil,
      sequence: 0,
      status: nil,
      summary: "Submit Quebec Income Tax Return for 2006",
      uid: "20070313T123432Z-456553@example.com",
      url: nil
    }
  end

  def timezone("America/New_York") do
    %ICal.Timezone{
      custom_properties: %{},
      daylight: [
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{},
          dtstart: ~N[1967-04-30 02:00:00],
          names: ["EDT"],
          offsets: %{from: -500, to: -400},
          rdates: [],
          rrule: %ICal.Recurrence{
            by_day: [{-1, :sunday}],
            by_hour: nil,
            by_minute: nil,
            by_month: [4],
            by_month_day: nil,
            by_second: nil,
            by_set_position: nil,
            by_week_number: nil,
            by_year_day: nil,
            count: nil,
            frequency: :yearly,
            interval: 1,
            until: ~U[1973-04-29 07:00:00Z],
            weekday: nil
          }
        },
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{},
          dtstart: ~N[1974-01-06 02:00:00],
          names: ["EDT"],
          offsets: %{from: -500, to: -400},
          rdates: [~N[1975-02-23 02:00:00]],
          rrule: nil
        },
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{},
          dtstart: ~N[1976-04-25 02:00:00],
          names: ["EDT"],
          offsets: %{from: -500, to: -400},
          rdates: [],
          rrule: %ICal.Recurrence{
            by_day: [{-1, :sunday}],
            by_hour: nil,
            by_minute: nil,
            by_month: [4],
            by_month_day: nil,
            by_second: nil,
            by_set_position: nil,
            by_week_number: nil,
            by_year_day: nil,
            count: nil,
            frequency: :yearly,
            interval: 1,
            until: ~U[1986-04-27 07:00:00Z],
            weekday: nil
          }
        },
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{},
          dtstart: ~N[1987-04-05 02:00:00],
          names: ["EDT"],
          offsets: %{from: -500, to: -400},
          rdates: [],
          rrule: %ICal.Recurrence{
            by_day: [{1, :sunday}],
            by_hour: nil,
            by_minute: nil,
            by_month: [4],
            by_month_day: nil,
            by_second: nil,
            by_set_position: nil,
            by_week_number: nil,
            by_year_day: nil,
            count: nil,
            frequency: :yearly,
            interval: 1,
            until: ~U[2006-04-02 07:00:00Z],
            weekday: nil
          }
        },
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{},
          dtstart: ~N[2007-03-11 02:00:00],
          names: ["EDT"],
          offsets: %{from: -500, to: -400},
          rdates: [],
          rrule: %ICal.Recurrence{
            by_day: [{2, :sunday}],
            by_hour: nil,
            by_minute: nil,
            by_month: [3],
            by_month_day: nil,
            by_second: nil,
            by_set_position: nil,
            by_week_number: nil,
            by_year_day: nil,
            count: nil,
            frequency: :yearly,
            interval: 1,
            until: nil,
            weekday: nil
          }
        }
      ],
      modified: ~U[2005-08-09 05:00:00Z],
      standard: [
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{},
          dtstart: ~N[1967-10-29 02:00:00],
          names: ["EST"],
          offsets: %{from: -400, to: -500},
          rdates: [],
          rrule: %ICal.Recurrence{
            by_day: [{-1, :sunday}],
            by_hour: nil,
            by_minute: nil,
            by_month: [10],
            by_month_day: nil,
            by_second: nil,
            by_set_position: nil,
            by_week_number: nil,
            by_year_day: nil,
            count: nil,
            frequency: :yearly,
            interval: 1,
            until: ~U[2006-10-29 06:00:00Z],
            weekday: nil
          }
        },
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{},
          dtstart: ~N[2007-11-04 02:00:00],
          names: ["EST"],
          offsets: %{from: -400, to: -500},
          rdates: [],
          rrule: %ICal.Recurrence{
            by_day: [{1, :sunday}],
            by_hour: nil,
            by_minute: nil,
            by_month: [11],
            by_month_day: nil,
            by_second: nil,
            by_set_position: nil,
            by_week_number: nil,
            by_year_day: nil,
            count: nil,
            frequency: :yearly,
            interval: 1,
            until: nil,
            weekday: nil
          }
        }
      ],
      id: "America/New_York",
      url: nil
    }
  end

  def timezone("America/New_York2") do
    %ICal.Timezone{
      custom_properties: %{},
      daylight: [
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{},
          dtstart: ~N[2007-03-11 02:00:00],
          names: ["EDT"],
          offsets: %{from: -500, to: -400},
          rdates: [],
          rrule: nil
        }
      ],
      modified: ~U[2005-08-09 05:00:00Z],
      standard: [
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{},
          dtstart: ~N[2007-11-04 02:00:00],
          names: ["EST"],
          offsets: %{from: -400, to: -500},
          rdates: [],
          rrule: nil
        }
      ],
      id: "America/New_York2",
      url: nil
    }
  end

  def timezone("America/New_York3") do
    %ICal.Timezone{
      custom_properties: %{},
      daylight: [
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{},
          dtstart: ~N[2007-03-11 02:00:00],
          names: ["EDT"],
          offsets: %{from: -500, to: -400},
          rdates: [],
          rrule: %ICal.Recurrence{
            by_day: [{2, :sunday}],
            by_hour: nil,
            by_minute: nil,
            by_month: [3],
            by_month_day: nil,
            by_second: nil,
            by_set_position: nil,
            by_week_number: nil,
            by_year_day: nil,
            count: nil,
            frequency: :yearly,
            interval: 1,
            until: nil,
            weekday: nil
          }
        }
      ],
      modified: ~U[2005-08-09 05:00:00Z],
      standard: [
        %ICal.Timezone.Properties{
          comments: ["This is for New York", "Another comment."],
          custom_properties: %{},
          dtstart: ~N[2007-11-04 02:00:00],
          names: ["EST"],
          offsets: %{from: -400, to: -500},
          rdates: [],
          rrule: %ICal.Recurrence{
            by_day: [{1, :sunday}],
            by_hour: nil,
            by_minute: nil,
            by_month: [11],
            by_month_day: nil,
            by_second: nil,
            by_set_position: nil,
            by_week_number: nil,
            by_year_day: nil,
            count: nil,
            frequency: :yearly,
            interval: 1,
            until: nil,
            weekday: nil
          }
        }
      ],
      id: "America/New_York3",
      url: "http://zones.example.com/tz/America-New_York.ics"
    }
  end

  def timezone("Fictitious") do
    %ICal.Timezone{
      custom_properties: %{},
      daylight: [
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{},
          dtstart: ~N[1987-04-05 02:00:00],
          names: ["EDT"],
          offsets: %{from: -500, to: -400},
          rdates: [],
          rrule: %ICal.Recurrence{
            by_day: [{1, :sunday}],
            by_hour: nil,
            by_minute: nil,
            by_month: [4],
            by_month_day: nil,
            by_second: nil,
            by_set_position: nil,
            by_week_number: nil,
            by_year_day: nil,
            count: nil,
            frequency: :yearly,
            interval: 1,
            until: ~U[1998-04-04 07:00:00Z],
            weekday: nil
          }
        }
      ],
      modified: ~U[1987-01-01 00:00:00Z],
      standard: [
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{},
          dtstart: ~N[1967-10-29 02:00:00],
          names: ["EST"],
          offsets: %{from: -400, to: -500},
          rdates: [],
          rrule: %ICal.Recurrence{
            by_day: [{-1, :sunday}],
            by_hour: nil,
            by_minute: nil,
            by_month: [10],
            by_month_day: nil,
            by_second: nil,
            by_set_position: nil,
            by_week_number: nil,
            by_year_day: nil,
            count: nil,
            frequency: :yearly,
            interval: 1,
            until: nil,
            weekday: nil
          }
        }
      ],
      id: "Fictitious",
      url: nil
    }
  end

  def timezone("Also Fictitious") do
    %ICal.Timezone{
      custom_properties: %{"X-Custom" => %{params: %{}, value: "Value"}},
      daylight: [
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{},
          dtstart: ~N[1987-04-05 02:00:00],
          names: ["EDT"],
          offsets: %{from: -500, to: -400},
          rdates: [],
          rrule: %ICal.Recurrence{
            by_day: [{1, :sunday}],
            by_hour: nil,
            by_minute: nil,
            by_month: [4],
            by_month_day: nil,
            by_second: nil,
            by_set_position: nil,
            by_week_number: nil,
            by_year_day: nil,
            count: nil,
            frequency: :yearly,
            interval: 1,
            until: ~U[1998-04-04 07:00:00Z],
            weekday: nil
          }
        },
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{
            "X-Custom-PROPERTY" => %{
              params: %{},
              value: "Property Value"
            }
          },
          dtstart: ~N[1999-04-24 02:00:00],
          names: ["EDT"],
          offsets: %{from: -500, to: -400},
          rdates: [],
          rrule: nil
        }
      ],
      standard: [
        %ICal.Timezone.Properties{
          comments: [],
          custom_properties: %{},
          dtstart: ~N[1967-10-29 02:00:00],
          names: ["EST"],
          offsets: %{from: -400, to: -500},
          rdates: [],
          rrule: %ICal.Recurrence{
            by_day: [{-1, :sunday}],
            by_hour: nil,
            by_minute: nil,
            by_month: [10],
            by_month_day: nil,
            by_second: nil,
            by_set_position: nil,
            by_week_number: nil,
            by_year_day: nil,
            count: nil,
            frequency: :yearly,
            interval: 1,
            until: nil,
            weekday: nil
          }
        }
      ],
      id: "Also Fictitious",
      url: nil
    }
  end
end
