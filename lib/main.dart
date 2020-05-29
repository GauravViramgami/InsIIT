import 'package:flutter/material.dart';
import 'package:instiapp/screens/academiccalendar.dart';
import 'package:instiapp/screens/editEvent.dart';
import 'package:instiapp/screens/addtext.dart';
import 'package:instiapp/screens/announcements.dart';
import 'package:instiapp/screens/articles.dart';
import 'package:instiapp/screens/complains.dart';
import 'package:instiapp/screens/email.dart';
import 'package:instiapp/screens/eventscalendar.dart';
import 'package:instiapp/screens/eventpage.dart';
import 'package:instiapp/screens/feedPage.dart';
import 'package:instiapp/screens/importantContacts.dart';
import 'package:instiapp/screens/menuBarBase.dart';
import 'package:instiapp/screens/messfeedback.dart';
import 'package:instiapp/screens/messmenu.dart';
import 'package:instiapp/screens/schedulePage.dart';
import 'package:instiapp/screens/shuttle.dart';
import 'package:instiapp/screens/signIn.dart';
import 'package:instiapp/utilities/constants.dart';
import 'package:instiapp/screens/Selecttime.dart';
import 'package:instiapp/screens/AvailableRooms.dart';
import 'package:instiapp/screens/form3.dart';
import 'package:instiapp/screens/roomservice.dart';
import 'package:instiapp/screens/eventDetail.dart';
import 'package:instiapp/screens/googlemap.dart';

void main() => runApp(MyApp());


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/signin',
      routes: {
        '/announcements': (context) => Announcements(),
        '/articles': (context) => Articles(),
        '/eventscalendar': (context) => EventsCalendar(),
        '/eventpage': (context) => EventPage(),
        '/schedule':(context) => SchedulePage(),
        '/feed': (context) => FeedPage(),
        // '/academiccalendar': (context) => AcademicCalendar(),
        '/importantcontacts': (context) => ImportantContacts(),
        '/complaints': (context) => Complains(),
        '/shuttle': (context) => Shuttle(),
        '/addtext': (context) => AddText(),
        '/Quicklinks': (context) => Email(),
        '/messmenu': (context) => MessMenu(),
        '/messfeedback': (context) => MessFeedBack(),
        '/signin': (context) => SignInPage(),
        '/menuBarBase': (context) => HomeWrapper(),
        '/bookingform': (context) => BookingForm(),
        '/selecttime' : (context) => SelectTime(),
        '/RoomBooking' : (context) => RoomService(),
        '/availablerooms' : (context) => AvailableRooms(),
        '/eventdetail' : (context) => EventDetail(),
        '/editevent' : (context) => EditEvent(),
        '/map' : (context) => MapPage(),
      },
      title: 'Instiapp',
      theme: ThemeData(primarySwatch: Colors.purple, fontFamily: 'OpenSans'),
    );
  }
}

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ScreenSize.size = MediaQuery.of(context).size;
    return MenuBarBase();
  }
}

