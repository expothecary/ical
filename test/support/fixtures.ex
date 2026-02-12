defmodule ICalendar.Test.Fixtures do
  def one_event do
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
      duration: "P15DT5H0M20S",
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
          rdates: [
            ~U[1997-01-01 00:00:00Z],
            ~U[1997-01-20 00:00:00Z],
            ~U[1997-02-17 00:00:00Z],
            ~U[1997-04-21 00:00:00Z]
          ]
        },
        %ICalendar.Event{
          uid: "2",
          rdates: [
            ~U[1997-01-01 00:00:00Z],
            ~U[1997-01-20 00:00:00Z],
            ~U[1997-02-17 00:00:00Z],
            ~U[1997-04-21 00:00:00Z]
          ]
        },
        %ICalendar.Event{
          uid: "3",
          rdates: [
            {~U[1997-01-01 18:00:00Z], ~U[1997-01-02 07:00:00Z]}
          ]
        },
        %ICalendar.Event{
          uid: "4"
        },
        %ICalendar.Event{
          uid: "5"
        },
        %ICalendar.Event{
          uid: "6"
        },
        %ICalendar.Event{
          uid: "7"
        }
      ]
    }
  end

  def statuses do
    %ICalendar{
      events: [
        %ICalendar.Event{
          uid: "1",
          status: :tentative
        },
        %ICalendar.Event{
          uid: "2",
          status: :confirmed
        },
        %ICalendar.Event{
          uid: "3",
          status: :cancelled
        },
        %ICalendar.Event{
          uid: "4",
          status: nil
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
