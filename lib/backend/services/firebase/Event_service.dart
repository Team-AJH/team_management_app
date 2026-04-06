import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:team_management_app/backend/models/Event.dart';

class EventService {
    final FirebaseFirestore _db = FirebaseFirestore.instance;

    // Collection reference helper
    CollectionReference<Map<String, dynamic>> getEventsCollection(String groupId) {
        return _db.collection('group').doc(groupId).collection('events');
    }

    // Creates a new event document in the "events" collection.
    Future<void> createEventDocument(String groupId, String name, String description, DateTime date, String location, String monthKey) async {
        final String eventId = getEventsCollection(groupId).doc().id;
        final Event newEvent = Event(
            eventId: eventId,
            name: name,
            description: description,
            date: date,
            location: location,
            groupId: groupId,
            monthKey: monthKey, 
            createdAt: DateTime.now(),
            eventStatus: EventStatus.Scheduled,
        );

        await getEventsCollection(groupId).doc(eventId).set(newEvent.toMap());
    }

    // Retrieves an event document by its event ID.
    Future<Event?> getEventDocument(String groupId, String eventId) async {
        final docSnapshot = await getEventsCollection(groupId).doc(eventId).get();

        if (docSnapshot.exists && docSnapshot.data() != null) {
            return Event.fromMap(docSnapshot.data()!, docSnapshot.id);
        }
        
        return null;
    }

    // Updates an existing event's information.
    Future<void> updateEventDocument(String groupId, String eventId, Map<String, dynamic> dataToUpdate) async {
        await getEventsCollection(groupId).doc(eventId).update(dataToUpdate);
    }

    // Deletes an event document.
    Future<void> deleteEventDocument(String groupId, String eventId) async {
        await getEventsCollection(groupId).doc(eventId).delete();
    }

//-------------------------SPECIFIC USE FUNCTIONS--------------------------------------------------

    // Function to get all the events of a group
    Future<List<Event>> getGroupEvents(String groupId) async {
        final querySnapshot = await getEventsCollection(groupId).get();
        return querySnapshot.docs.map((doc) => Event.fromMap(doc.data(), doc.id)).toList();
    }

    // Function to get all the events of a specific month 
    Future<List<Event>> getGroupEventsByMonth(String groupId, String monthKey) async {
        final querySnapshot = await getEventsCollection(groupId).where('monthKey', isEqualTo: monthKey).get();
        return querySnapshot.docs.map((doc) => Event.fromMap(doc.data(), doc.id)).toList();
    }

    // Function to update the status of an event
    Future<void> updateEventStatus(String groupId, String eventId, EventStatus status) async {
       await updateEventDocument(groupId, eventId, {'eventStatus': status.name});
    }

    //function to update event name
    Future<void> updateEventName(String groupId, String eventId, String name) async {
        await updateEventDocument(groupId, eventId, {'name': name});
    }

    //function to update event date
    Future<void> updateEventDate(String groupId, String eventId, DateTime date) async {
       await updateEventDocument(groupId, eventId, {'date': date});
    }

    //function to update event location
    Future<void> updateEventLocation(String groupId, String eventId, String location) async {
        await updateEventDocument(groupId, eventId, {'location': location});
    }

    // Function to update teams
    Future<void> updateTeams(String groupId, String eventId, List<String> team1, List<String> team2) async {
        await updateEventDocument(groupId, eventId, {'team1': team1, 'team2': team2});
    }
}