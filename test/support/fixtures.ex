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
      class: "PRIVATE",
      geo: {43.6978819, -79.3810277}
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
