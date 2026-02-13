defmodule ICalendar.Test.Fixtures do
  @moduledoc false

  def one_event(which \\ :deserialize)

  def one_event(:serialize) do
    %ICalendar.Event{
      summary: "Going fishing",
      description: "Escape from the world. Stare at some water.",
      comments: ["Don't forget to take something to eat !"],
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
      created: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
      contacts: ["Joe Blow", "Jill Bar"],
      priority: "",
      attachments: [
        %ICalendar.Attachment{
          data_type: :cid,
          data: "jsmith.part3.960817T083000.xyzMail@example.com",
          mimetype: nil
        },
        %ICalendar.Attachment{
          data_type: :uri,
          data: "ftp://example.com/pub/reports/r-960812.ps",
          mimetype: "application/postscript"
        },
        %ICalendar.Attachment{
          data_type: :base8,
          data: "Some plain text",
          mimetype: nil
        },
        %ICalendar.Attachment{
          data_type: :base64,
          data: "VGhlIHF1aWNrIGJyb3duIGZveCBqdW1wcyBvdmVyIHRoZSBsYXp5IGRvZy4",
          mimetype: "text/plain"
        },
        %ICalendar.Attachment{
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
    %ICalendar.Event{
      dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 0}}),
      dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 0}}),
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}}),
      summary: "Going fishing",
      description: "Escape from the world. Stare at some water.",
      location: "123 Fun Street, Toronto ON, Canada",
      status: :tentative,
      categories: ["Fishing", "Nature"],
      comments: ["Don't forget to take something to eat !"],
      contacts: ["Jim Dolittle, ABC Industries, +1-919-555-1234"],
      created: ~U[1996-03-29 13:30:00Z],
      class: "PRIVATE",
      duration: %ICalendar.Duration{
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
    %ICalendar.Event{
      uid: "YES",
      comments: ["Should appear normally"]
    }
  end

  def transparencies do
    %ICalendar{
      events: [
        %ICalendar.Event{
          uid: "1",
          transparency: :transparent
        },
        %ICalendar.Event{
          uid: "2",
          transparency: :opaque
        },
        %ICalendar.Event{
          uid: "3",
          transparency: nil
        }
      ]
    }
  end

  def rdates do
    %ICalendar{
      events: [
        %ICalendar.Event{
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
        %ICalendar.Event{
          uid: "2",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}}),
          rdates: [
            ~U[1997-01-01 00:00:00Z],
            ~U[1997-01-20 00:00:00Z],
            ~U[1997-02-17 00:00:00Z],
            ~U[1997-04-21 00:00:00Z]
          ]
        },
        %ICalendar.Event{
          uid: "3",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}}),
          rdates: [
            {~U[1997-01-01 18:00:00Z], ~U[1997-01-02 07:00:00Z]},
            {~U[1998-01-01 18:00:00Z], ~U[1998-01-02 07:00:00Z]},
            {~U[1999-01-01 18:00:00Z],
             %ICalendar.Duration{positive: true, time: {0, 0, 0}, days: 0, weeks: 2}}
          ]
        },
        %ICalendar.Event{
          uid: "4",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICalendar.Event{
          uid: "5",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICalendar.Event{
          uid: "6",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICalendar.Event{
          uid: "7",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        }
      ]
    }
  end

  def statuses(which \\ :deserialize)

  def statuses(:deserialize) do
    %ICalendar{
      events: [
        %ICalendar.Event{
          uid: "1",
          status: :tentative,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICalendar.Event{
          uid: "2",
          status: :confirmed,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICalendar.Event{
          uid: "3",
          status: :cancelled,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICalendar.Event{
          uid: "4",
          status: nil,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        }
      ]
    }
  end

  def statuses(:serialize) do
    %ICalendar{
      events: [
        %ICalendar.Event{
          uid: "1",
          status: :tentative,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICalendar.Event{
          uid: "2",
          status: :confirmed,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICalendar.Event{
          uid: "3",
          status: :cancelled,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICalendar.Event{
          uid: "4",
          status: nil,
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        },
        %ICalendar.Event{
          uid: "5",
          status: "CUSTOM",
          dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}})
        }
      ]
    }
  end

  def one_truncated_event do
    %ICalendar.Event{
      dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 0}}),
      dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 0}}),
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}}),
      summary: "Going fishing",
      description: "Escape from the world. Stare at some water.",
      location: "123 Fun Street, Toronto ON, Canada",
      status: :tentative,
      categories: ["Fishing", "Nature"],
      comments: ["Don't forget to take something to eat !"],
      contacts: ["Jim Dolittle, ABC Industries, +1-919-555-1234"],
      class: "PRIVATE",
      geo: {43.6978819, -79.3810277},
      resources: ["Nettoyeur haute pression"]
    }
  end

  def broken_dates_event do
    %ICalendar.Event{
      dtstart: nil,
      dtend: nil,
      dtstamp: nil,
      created: nil,
      exdates: [],
      uid: "1"
    }
  end

  def attendees do
    %ICalendar{
      product_id: "-//Elixir ICalendar//EN",
      scale: "GREGORIAN",
      method: nil,
      version: "2.0",
      events: [
        %ICalendar.Event{
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
          prodid: nil,
          status: nil,
          organizer: nil,
          sequence: nil,
          summary: nil,
          url: nil,
          geo: nil,
          priority: nil,
          transparency: nil,
          attendees: [
            %ICalendar.Attendee{
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
            %ICalendar.Attendee{
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
            %ICalendar.Attendee{
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
end
