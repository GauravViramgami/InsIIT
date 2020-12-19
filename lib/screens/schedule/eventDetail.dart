import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instiapp/classes/scheduleModel.dart';

class EventDetail extends StatefulWidget {
  @override
  _EventDetailState createState() => _EventDetailState();
}

class _EventDetailState extends State<EventDetail> {
  Map eventModelData = {};
  List<Widget> attendance;

  List<Widget> attendanceManager(Map<DateTime, String> attendanceManager) {
    List<Widget> listTiles = [];
    attendanceManager.forEach((DateTime time, String attendance) {
      listTiles.add(ListTile(
        title: Text('${time.day} /${time.month} /${time.year}'),
        trailing: Text(attendance),
      ));
    });
    return listTiles;
  }

  String stringReturn(String text) {
    if (text == null) {
      return 'None';
    } else {
      return text;
    }
  }

  String twoDigitTime(String text) {
    if (text.length == 1) {
      String _text = '0' + text;
      return _text;
    } else {
      return text;
    }
  }

  String time(DateTime time) {
    if (time == null) {
      return "Whole Day";
    } else {
      return twoDigitTime(time.hour.toString()) +
          ':' +
          twoDigitTime(time.minute.toString());
    }
  }

  Widget body(EventModel event) {
    if (event.isCourse) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(event.courseName,
                style: TextStyle(
                    color: Colors.black.withAlpha(255),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(event.courseId,
                style: TextStyle(
                    color: Colors.black.withAlpha(150),
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text(event.eventType,
                style: TextStyle(
                  color: Colors.black.withAlpha(255),
                  fontStyle: FontStyle.italic,
                )),
            SizedBox(
              height: 10,
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Happens at ',
                  ),
                  TextSpan(
                    text: event.location,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 10,
            ),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Between ',
                  ),
                  TextSpan(
                    text: time(event.start),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: ' and ',
                  ),
                  TextSpan(
                    text: time(event.end),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 10,
            ),
            (event.remarks == null)
                ? Container()
                : Text('Remarks: ${event.remarks}',
                    style: TextStyle(
                        color: Colors.black.withAlpha(255),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
            SizedBox(
              height: 8,
            ),
            Text('Instructors: ',
                style: TextStyle(
                    color: Colors.black.withAlpha(255),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            SizedBox(
              height: 8,
            ),
            Column(
              children: (event.instructors == null) ? [Container()] :event.instructors.map<Widget>((String instructor) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(instructor,
                      style: TextStyle(
                        color: Colors.black.withAlpha(255),
                        // fontWeight: FontWeight.bold,
                      )),
                );
              }).toList(),
            ),
            SizedBox(
              height: 10,
            ),
            Text('${event.credits} credits',
                style: TextStyle(
                  color: Colors.black.withAlpha(255),
                  fontWeight: FontWeight.bold,
                )),
            (event.preRequisite == '-')
                ? Container()
                : Text('Pre-requisite: ${event.preRequisite}',
                    style: TextStyle(
                        color: Colors.black.withAlpha(255),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
            ExpansionTile(
              key: GlobalKey(),
              title: Text('View Attendance'),
              children: attendance,
            )
          ],
        ),
      );
    } else if (event.isExam) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 10,
            ),
            Text(event.courseName,
                style: TextStyle(
                    color: Colors.black.withAlpha(255),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(event.courseId,
                style: TextStyle(
                    color: Colors.black.withAlpha(150),
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            Text('ClassRoom: ${event.location}',
                style: TextStyle(
                    color: Colors.black.withAlpha(255),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            SizedBox(
              height: 10,
            ),
            Text('Roll Numbers: ${event.rollNumbers}',
                style: TextStyle(
                    color: Colors.black.withAlpha(255),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            SizedBox(
              height: 10,
            ),
            Text('Time: ' + time(event.start) + ' to ' + time(event.end),
                style: TextStyle(
                    color: Colors.black.withAlpha(255),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            SizedBox(
              height: 10,
            ),
            Text('Type: ${event.eventType}',
                style: TextStyle(
                    color: Colors.black.withAlpha(255),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 10,
            ),
            Text('Event: ' + stringReturn(event.summary),
                style: TextStyle(
                    color: Colors.black.withAlpha(255),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            SizedBox(
              height: 10,
            ),
            Text('Invited by: ' + stringReturn(event.creator),
                style: TextStyle(
                    color: Colors.black.withAlpha(255),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            SizedBox(
              height: 10,
            ),
            Text('Description: ' + stringReturn(event.description),
                style: TextStyle(
                    color: Colors.black.withAlpha(255),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            SizedBox(
              height: 10,
            ),
            Text('Time: ' + time(event.start) + ' To ' + time(event.end),
                style: TextStyle(
                    color: Colors.black.withAlpha(255),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            SizedBox(
              height: 10,
            ),
            Text('Location: ' + stringReturn(event.location),
                style: TextStyle(
                    color: Colors.black.withAlpha(255),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            SizedBox(
              height: 10,
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    eventModelData = ModalRoute.of(context).settings.arguments;
    EventModel event = eventModelData['eventModel'];
    if (event.isCourse) {
      attendance = attendanceManager(event.attendanceManager);
    }
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Details',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: body(event),
      ),
    );
  }
}
