import EventKit
import ArgumentParser

struct Participant: Codable {
    var name: String
    var url: String 
}

struct Event: Codable {
    var title: String
    var startDate: Date
    var endDate: Date
    var allDay: Bool
    var calendar: String
    // var floating: Int
    // var recurrence:   EKRecurrenceRule <0x6000036f1f90> RRULE FREQ=WEEKLY;INTERVAL=1;BYDAY=TU,WE,TH;
    // var travelTime: Null
    // var startLocation: Null
    var organizer: Participant?
    var attendees: [Participant?]
    var notes: String?
    var status: String 

}

extension EKParticipant {
    func toParticipant() -> Participant {
        return Participant(name: self.name ?? "", url: self.url.description)
    }
}

extension EKEvent {

    func toEvent() -> Event {
        var attendees: [Participant?] = []
        for participant in self.attendees ?? [] {
            attendees.append(contentsOf: [participant.toParticipant()] )
        }

        var status: String = "";
        switch self.status {
            case EKEventStatus.none: status = "none"
            case EKEventStatus.canceled: status = "canceled"
            case EKEventStatus.confirmed: status = "confirmed"
            case EKEventStatus.tentative: status = "tentative"
            @unknown default: break
        }

        return Event(
            title: self.title, 
            startDate: self.startDate,
            endDate: self.endDate,
            allDay: self.isAllDay,
            calendar: self.calendar.title,
            organizer: self.organizer?.toParticipant(),
            attendees: attendees,
            notes: self.notes,
            status: status
        )
    }
}

@main
struct Main: ParsableCommand {
    @Argument(help: "Start date")
    var startPeriod: String
    @Argument(help: "End date")
    var endPeriod: String

    func run() {
        let start =  GetEvents.parseDate(isoDate: startPeriod)
        if (start == nil) {
            print("Could not parse start date: '\(startPeriod)'. Make sure it's a valid ISO8601 date")
            return
        } 
        let end = GetEvents.parseDate(isoDate: endPeriod)
        if (end == nil) {
            print("Could not parse end date: '\(endPeriod)'. Make sure it's a valid ISO8601 date")
            return
        }

        let getEvents = GetEvents(startDate: start!, endDate: end!)

        getEvents.run()
    }
}

public struct GetEvents {
    var startDate: Date;
    var endDate: Date;
    let store = EKEventStore()


    func run() {
        let status = EKEventStore.authorizationStatus(for: EKEntityType.event)
        switch (status) {
            case .notDetermined:
                self.requestAccessToCalendar()
            case .authorized:
                self.fetchEventsFromCalendar()
                break
            case .restricted, .denied: fallthrough
            @unknown default: break
        }
    }

    public func requestAccessToCalendar() {

        store.requestAccess(to: EKEntityType.event) { (accessGranted, error) in
            self.fetchEventsFromCalendar()
        }
    }

    public func fetchEventsFromCalendar() {
        let calendars = store.calendars(for: .event)
        let predicate =  store.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)

        var events: [Event] = [];
        for event in store.events(matching: predicate) {
           events.append(contentsOf: [event.toEvent()]) 
        }


        let encoder = JSONEncoder()
        // encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(events)
            print(String(data: data, encoding: .utf8)!)
        } catch  {
            print("Error")
        }
    }


    public static func parseDate(isoDate: String) -> Date? {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.date(from:isoDate)
    }
}

