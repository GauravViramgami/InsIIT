import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:instiapp/screens/roomBooking/Selecttime.dart';
import 'package:instiapp/screens/roomBooking/functions.dart';
import 'package:instiapp/utilities/constants.dart';
import 'package:http/http.dart' as http;

class BookingForm extends StatefulWidget {
  @override
  _BookingFormState createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  TextEditingController _mobileNoController;
  TextEditingController _purposeController;
  TextEditingController _bioController;

  Map roomData = {};

  void initState() {
    super.initState();
    _mobileNoController = TextEditingController();
    _purposeController = TextEditingController();
    _bioController = TextEditingController();

  }

  void dispose() {
    _mobileNoController.dispose();
    _purposeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  bookRoom(RoomTime time, Room room) async{
    var queryParameters = {
      'api_key': 'NIKS',
      'room_id': room.roomId,
    };
    var uri = Uri.https(
      baseUrl,
      '/addBooking',
      queryParameters,
    );
    print('Booking Room: ' + uri.toString());
    var jsonBody = jsonEncode({
      "booked_by": {
        "user_id": time.userId,
        "full_name": time.name,
        "image_link": time.url,
        "bio": time.bio,
        "contact": int.parse(time.mobNo),
      },
      "purpose": time.purpose,
      "start": time.start.millisecondsSinceEpoch,
      "end": time.end.millisecondsSinceEpoch,
    });
    print(jsonBody);
    var response = await http.post(
      uri,
      body: jsonBody,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      }
    );
    print(response.statusCode);

    //print("SUCCESS: " + jsonDecode(response.body)['success'].toString());
    Navigator.pushReplacementNamed(context, '/RoomBooking');

  }

  @override
  Widget build(BuildContext context) {

    roomData = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text('Your Details'),
      ),
      body:Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 20.0,),
            Row(
              children: <Widget>[
                Text(
                  'Name:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 15,),
                Text(
                  gSignIn.currentUser.displayName,
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.0,),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Mobile Number',),
              controller: _mobileNoController,
            ),
            SizedBox(height: 20.0,),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Purpose',),
              controller: _purposeController,
            ),
            SizedBox(height: 20.0,),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Your Bio',),
              controller: _bioController,
            ),
            FlatButton(
              onPressed: () {
                if (_mobileNoController.text == '' || _purposeController.text == '' || _bioController.text == '') {
                  showDialog(
                    context: context,
                    builder: (_) => new AlertDialog(
                      content: Text("Please Enter Mobile number,purpose and bio!"),
                    ),
                  );
                } else {
                  bookRoom(RoomTime(userId: gSignIn.currentUser.email, name: gSignIn.currentUser.displayName, mobNo: _mobileNoController.text, start: start,  end: end,  purpose: _purposeController.text, bio: _bioController.text, url: gSignIn.currentUser.photoUrl), Room(block: roomData['_block'], roomno: roomData['_room'], roomId: roomData['_id']));
                }
              },
              child: Text('Book ${roomData['_block']}/${roomData['_room']}'),
            )
          ],
        ),
      ),
    );
  }
}


