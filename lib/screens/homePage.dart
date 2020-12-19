import 'dart:convert';
import 'dart:io';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instiapp/messMenu/base.dart';
import 'package:instiapp/screens/loading.dart';
import 'package:instiapp/screens/map/googlemap.dart';
import 'package:instiapp/screens/shuttle.dart';
import 'package:instiapp/utilities/bottomNavBar.dart';
import 'package:instiapp/utilities/constants.dart';
import 'package:instiapp/utilities/globalFunctions.dart';
import 'package:instiapp/classes/weekdaycard.dart';
import 'package:instiapp/classes/contactcard.dart';
import 'package:instiapp/classes/buses.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'email.dart';
import 'package:instiapp/classes/scheduleModel.dart';
import 'package:googleapis/classroom/v1.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:instiapp/screens/signIn.dart';
import 'package:path_provider/path_provider.dart';
//(beta)import 'package:instiapp/screens/roomBooking/roomservice.dart';

import 'package:instiapp/screens/misc.dart';
//(beta)import 'package:instiapp/classes/tlclass.dart';
import 'feed/feedPage.dart';

class HomePage extends StatefulWidget {
  HomePage(this.notifyParent);
  final Function() notifyParent;
  @override
  _HomePageState createState() => _HomePageState();
}

List<FoodCard> foodCards;
Map<String, String> foodIllustration = {};
List<ContactCard> contactCards;
List<Buses> buses;
List<Data> emails;
List<List<String>> foodVotes;
List<TodayCourse> todayCourses;
List<MyCourse> myCourses;
List<EventModel> removedEvents;
List<EventModel> userAddedCourses;
List<EventModel> examCourses;
List<EventModel> eventsList;
//(beta)List<Tinkerer> tlDataList;
//(beta)List<Tinkerer> machinesTL;

bool mainPageLoading = true;
int selectedIndex = 0;
List<int> prevIndexes = [];

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage> {
  var startpos, endpos;
  List<EventModel> twoEvents;
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(selectedIndex);
      }
    });
    reloadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void reloadData() {
    loadMessData();
    loadFoodIllustrationData();
    loadlinks();
    loadImportantContactData();
    loadShuttleData();
    loadFoodVotesData();
    loadCourseData();
    loadRemovedCoursesData();
    loadUserAddedCoursesData();
    loadExamTimeTableData();
    //(beta)loadCertificateData();
    //(beta)loadTlData();
  }

  /*(beta)loadCertificateData() async {
    emailIds = [];
    sheetTL.getData('CertificateList!A:E').listen((data) {
      var certificateData = (data);
      certificateData.forEach((i) {
        emailIds.add(data[1]);
      });
    });
  }*/

  /*(beta)loadTlData() async {
    sheet.getData('TLContacts!A:D').listen((data) {
      var tlData = data;
      tlDataList = [];
      tlData.removeAt(0);
      tlData.forEach((detail) {
        tlDataList.add(Tinkerer(
          name: detail[0],
          mobNo: detail[1].toString(),
          machine: detail[2],
          job: detail[3].split('+'),
        ));
      });
     makeMachines(tlDataList);
    });


  }*/

  /*(beta)makeMachines(List<Tinkerer> tlDataList) {
    machinesTL = [];
    tlDataList.forEach((Tinkerer person) {
      if(person.machine != '-'){
        person.isMachine = true;
        machinesTL.add(person);
      }
    });
  }*/

  prepareEventsList() {
    List<calendar.Event> todayEvents;
    List<EventModel> currentDayCourses;
    List<EventModel> currentDayExamCourses;
    List<EventModel> mergedCourses;

    eventsList = [];
    if (userAddedCourses != null) {
      userAddedCourses.forEach((EventModel model) {
        bool shouldContain = true;
        if (removedEvents != null) {
          removedEvents.forEach((EventModel removedEvent) {
            if (removedEvent.courseId == model.courseId &&
                removedEvent.courseName == model.courseName &&
                removedEvent.eventType == model.eventType) {
              shouldContain = false;
            }
          });
        }
        if (model.day == DateTime
            .now()
            .weekday && shouldContain) {
          eventsList.add(model);
        }
      });
    }
    currentDayExamCourses = todayExamCourses(examCourses);
    currentDayExamCourses.forEach((EventModel model) {
      bool shouldContain = true;
      if (removedEvents != null) {
        removedEvents.forEach((EventModel removedEvent) {
          if (removedEvent.isExam) {
            if (removedEvent.courseId == model.courseId &&
                removedEvent.courseName == model.courseName) {
              shouldContain = false;
            }
          }
        });
      }
      if (shouldContain) {
        eventsList.add(model);
      }
    });
    currentDayCourses = makeCourseEventModel(todayCourses, myCourses);
    mergedCourses = mergeSameCourses(currentDayCourses);
    mergedCourses.forEach((EventModel model) {
      bool shouldContain = true;
      if (removedEvents != null) {
        removedEvents.forEach((EventModel removedEvent) {
          if (removedEvent.isCourse) {
            if (removedEvent.courseId == model.courseId &&
                removedEvent.courseName == model.courseName &&
                removedEvent.eventType == model.eventType) {
              shouldContain = false;
            }
          }
        });
      }
      if (shouldContain) {
        eventsList.add(model);
      }
    });
    todayEvents = todayEventsList(eventsWithoutRepetition);
    todayEvents.forEach((calendar.Event event) {
      bool shouldContain = true;
      if (removedEvents != null) {
        removedEvents.forEach((EventModel removedEvent) {
          if (removedEvent.isCourse == false && removedEvent.isExam == false) {
            if (removedEvent.description == event.description &&
                removedEvent.summary == event.summary &&
                removedEvent.location == event.location &&
                removedEvent.creator == event.creator.displayName &&
                removedEvent.remarks == event.status) {
              shouldContain = false;
            }
          }
        });
      }
      if (shouldContain) {
        eventsList.add(EventModel(
            start: event.start.dateTime.toLocal(),
            end: event.end.dateTime.toLocal(),
            isCourse: false,
            isExam: false,
            courseName: null,
            description: event.description,
            summary: event.summary,
            location: event.location,
            creator: event.creator.displayName,
            remarks: event.status));
      }
    });
    if (eventsList != null && eventsList.length != 0) {
      quickSort(eventsList, 0, eventsList.length - 1);
    }
  }

  loadShuttleData() async {
    sheet.getData('BusRoutes!A:H').listen((data) {
      var shuttleDataList = data;
      buses = [];
      shuttleDataList.removeAt(0);
      shuttleDataList.forEach((bus) {
        buses.add(Buses(
          origin: bus[0],
          destination: bus[1],
          time: bus[2],
          url: bus[4],
          hour: int.parse(bus[2].split(':')[0]),
          minute: int.parse(bus[2].split(':')[1]),
        ));
      });
    });
  }

  loadExamTimeTableData() async {
    sheet.getData('ExamTimeTable!A:H').listen((data) {
      examCourses = makeMyExamCoursesList(data, coursesWithoutRepetition);
    });
  }

  List<EventModel> makeMyExamCoursesList(List data, List<Course> _courses) {
    List<EventModel> myExamCourses = [];

    if (_courses != null) {
      _courses.forEach((Course course) {
        bool mine = false;
        var baseLc = data[3];
        data.forEach((var lc) {
          if (mine == false && lc.length > 3) {
            if (lc[0] != '' && lc[0] != '-' && lc[1] != '' && lc[1] != '-') {
              baseLc = lc;
            }
            if (lc[2] != '' && lc[2] != '-') {
              if (lc[2].replaceAll(' ', '').contains(new RegExp(
                      course.name.replaceAll(' ', ''),
                      caseSensitive: false)) ||
                  course.name.replaceAll(' ', '').contains(new RegExp(
                      lc[2].replaceAll(' ', ''),
                      caseSensitive: false)) ||
                  compareStrings(course.name, lc[2]) ||
                  lc[3].replaceAll(' ', '').contains(new RegExp(
                      course.name.replaceAll(' ', ''),
                      caseSensitive: false)) ||
                  course.name.replaceAll(' ', '').contains(new RegExp(
                      lc[3].replaceAll(' ', ''),
                      caseSensitive: false)) ||
                  compareStrings(course.name, lc[3])) {
                List<DateTime> time = getTime(baseLc);
                lc.addAll(['null','null','null','null','null']);
                myExamCourses.add(EventModel(
                  isCourse: false,
                  isExam: true,
                  start: time[0],
                  end: time[1],
                  courseId: lc[2],
                  courseName: lc[3],
                  location: lc[5].toString(),
                  rollNumbers: lc[7].toString(),
                  eventType: 'Exam',
                ));
                mine = true;
              }
            }
          }
        });
      });
    }

    return myExamCourses;
  }

  Map<String, int> monthData = {
    'January': 1,
    'February': 2,
    'March': 3,
    'April': 4,
    'May': 5,
    'June': 6,
    'July': 7,
    'August': 8,
    'September': 9,
    'October': 10,
    'November': 11,
    'December': 12,
  };

  List<DateTime> getTime(var baseLc) {
    int index = 1;

    var date = baseLc[0].split(',');
    var dayWithMonth = date[1].split(' ');
    if (dayWithMonth.length == 2) {
      index = 0;
    }
    int year = int.parse(date[2].replaceAll(' ', ''));
    int day = int.parse(dayWithMonth[index + 1].replaceAll(' ', ''));
    int month = monthData[dayWithMonth[index].replaceAll(' ', '')];
    var dayTime = baseLc[1].split('-');
    var startTime = dayTime[0].replaceAll(' ', '').split(':');
    var endTime = dayTime[1].replaceAll(' ', '').split(':');
    int startHour = int.parse(startTime[0]);
    int startMinute = int.parse(startTime[1].substring(0, 2));
    int endHour = int.parse(endTime[0]);
    int endMinute = int.parse(endTime[1].substring(0, 2));
    List<DateTime> time = [
      DateTime(year, month, day, startHour, startMinute),
      DateTime(year, month, day, endHour, endMinute)
    ];
    return time;
  }

  loadRemovedCoursesData() async {
    getRemovedEventsData().listen((data) {
      print(data);
      removedEvents = makeRemovedEventsList(data);
    });
  }

  List<EventModel> makeRemovedEventsList(var removedEventsDataList) {
    List<EventModel> _removedEvents = [];

    if (removedEventsDataList != null && removedEventsDataList.length != 0) {
      removedEventsDataList.forEach((var lc) {
        if (lc[0] == 'course') {
          _removedEvents.add(EventModel(
            isCourse: true,
            isExam: false,
            courseId: lc[1],
            courseName: lc[2],
            eventType: lc[3],
          ));
        } else if (lc[0] == 'exam') {
          _removedEvents.add(EventModel(
            isCourse: false,
            isExam: true,
            courseId: lc[1],
            courseName: lc[2],
            eventType: lc[3],
          ));
        } else {
          _removedEvents.add(EventModel(
            isCourse: false,
            isExam: false,
            description: lc[1],
            summary: lc[2],
            location: lc[3],
            creator: lc[4],
            remarks: lc[5],
          ));
        }
      });
    }

    return _removedEvents;
  }

  Future<File> _localFileForRemovedEvents() async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    String filename = tempPath + 'removedCourses' + '.csv';
    return File(filename);
  }

  Stream<List<List<dynamic>>> getRemovedEventsData() async* {
    var file = await _localFileForRemovedEvents();
    bool exists = await file.exists();
    if (exists) {
      await file.open();
      String values = await file.readAsString();
      List<List<dynamic>> rowsAsListOfValues =
      CsvToListConverter().convert(values);
      // print("FROM LOCAL: ${rowsAsListOfValues[2]}");

      yield rowsAsListOfValues;
    } else {
      yield [];
    }
  }

  loadUserAddedCoursesData () async {
    getUserAddedCoursesData().listen((data) {
      userAddedCourses = makeUserAddedCoursesList(data);
    });
  }

  List<EventModel> makeUserAddedCoursesList(var userAddedCoursesDataList) {
    List<EventModel> _userAddedCourses = [];

    if (userAddedCoursesDataList != null &&
        userAddedCoursesDataList.length != 0) {
      userAddedCoursesDataList.forEach((var lc) {
        print(lc);
        _userAddedCourses.add(EventModel(
          isCourse: true,
          isExam: false,
          courseId: lc[0],
          courseName: lc[1],
          location: lc[2],
          credits: lc[3].toString(),
          preRequisite: lc[4],
          start: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, int.parse(lc[5].split(':')[0]), int.parse(lc[5].split(':')[1])),
          end: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, int.parse(lc[6].split(':')[0]), int.parse(lc[6].split(':')[1])),
          eventType: 'Course',
          day: lc[7],
          attendanceManager: attendanceData
        ));
      });
    }

    return _userAddedCourses;
  }

  Future<File> _localFileForUserAddedCourses() async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    String filename = tempPath + 'userAddedCourses' + '.csv';
    return File(filename);
  }

  Stream<List<List<dynamic>>> getUserAddedCoursesData() async* {
    var file = await _localFileForUserAddedCourses();
    bool exists = await file.exists();
    if (exists) {
      await file.open();
      String values = await file.readAsString();
      List<List<dynamic>> rowsAsListOfValues =
      CsvToListConverter().convert(values);
      // print("FROM LOCAL: ${rowsAsListOfValues[2]}");

      yield rowsAsListOfValues;
    } else {
      yield [];
    }
  }

  loadCourseData() async {
    sheet.getData('slots!A:F').listen((data) {
      todayCourses = makeTodayTimeSlotList(data);
    });

    sheet.getData('timetable!A:Q').listen((data) {
      myCourses = makeMyCourseList(data, coursesWithoutRepetition);
    });
  }

  bool compareStrings(String str1, String str2) {
    if (str1.compareTo(str2) == 0) {
      return true;
    } else {
      return false;
    }
  }

  List<MyCourse> makeMyCourseList(List data, List<Course> _courses) {
    List<MyCourse> _myCourses = [];

    if (_courses != null) {
      _courses.forEach((Course course) {
        bool mine = false;
        data.forEach((var lc) {
          if (mine == false &&
              lc[0] != '-' &&
              lc[0] != '' &&
              lc[1] != '-' &&
              lc[1] != '') {
            if (lc[0].replaceAll(' ', '').contains(new RegExp(
                    course.name.replaceAll(' ', ''),
                    caseSensitive: false)) ||
                course.name.replaceAll(' ', '').contains(new RegExp(
                    lc[0].replaceAll(' ', ''),
                    caseSensitive: false)) ||
                compareStrings(course.name, lc[0]) ||
                lc[1].replaceAll(' ', '').contains(new RegExp(
                    course.name.replaceAll(' ', ''),
                    caseSensitive: false)) ||
                course.name.replaceAll(' ', '').contains(new RegExp(
                    lc[1].replaceAll(' ', ''),
                    caseSensitive: false)) ||
                compareStrings(course.name, lc[1])) {
              _myCourses.add(MyCourse(
                  courseCode: lc[0],
                  courseName: lc[1],
                  noOfLectures: lc[2].toString(),
                  noOfTutorials: lc[3].toString(),
                  credits: lc[5].toString(),
                  instructors: lc[6].split(','),
                  preRequisite: lc[10],
                  lectureCourse:
                      lc[11].split('(')[0].replaceAll(' ', '').split('+'),
                  lectureLocation: returnLocation(lc[11]),
                  tutorialCourse:
                      lc[12].split('(')[0].replaceAll(' ', '').split('+'),
                  tutorialLocation: returnLocation(lc[12]),
                  labCourse:
                      lc[13].split('(')[0].replaceAll(' ', '').split('+'),
                  labLocation: returnLocation(lc[13]),
                  remarks: lc[14],
                  courseBooks: lc[15]));
              mine = true;
            }
          }
        });
      });
    }

    return _myCourses;
  }

  String returnLocation(var text) {
    if (text.split('(').length == 1) {
      return 'None';
    } else {
      return text.split('(')[1].replaceAll(')', '');
    }
  }

  List<TodayCourse> makeTodayTimeSlotList(var courseSlotDataList) {
    int day = DateTime.now().weekday;
    List<TodayCourse> courses = [];
    if (day != 6 && day != 7) {
      courseSlotDataList.removeAt(0);
      courseSlotDataList.removeAt(0);

      courseSlotDataList.forEach((var lc) {
        List<DateTime> time = returnTime(lc[0]);
        courses.add(TodayCourse(start: time[0], end: time[1], course: lc[day]));
      });
    }
    return courses;
  }

  List<DateTime> returnTime(String time) {
    List<DateTime> seTime = [];
    DateTime today = DateTime.now();
    var list1 = time.split('-');
    var startString = list1[0].split(':');
    var endString = list1[1].split(':');
    seTime = [
      DateTime(today.year, today.month, today.day, int.parse(startString[0]),
          int.parse(startString[1])),
      DateTime(today.year, today.month, today.day, int.parse(endString[0]),
          int.parse(endString[1]))
    ];

    return seTime;
  }

  loadImportantContactData() async {
    sheet.getData('Contacts!A:E').listen((data) {
      makeContactList(data);
    });
  }

  loadlinks() async {
    sheet.getData('QuickLinks!A:C').listen((data) {
      var d = (data);
      d.removeAt(0);
      emails = [];
      d.forEach((i) {
        emails.add(Data(descp: i[1], name: i[0], email: i[2]));
      });
    });
  }

  loadFoodVotesData() async {
    getFoodVotesData().listen((data) {
      foodVotes = makeFoodVotesList(data);
    });
  }

  List<List<String>> makeFoodVotesList(var foodVotesList) {
    List<List<String>> _foodVotes = [];

    if (foodVotesList != null && foodVotesList.length != 0) {
      foodVotesList.forEach((var lc) {
        _foodVotes.add([lc[0], lc[1].toString()]);
      });
    }

    return _foodVotes;
  }

  Stream<List<List<dynamic>>> getFoodVotesData() async* {
    var file = await _localFile('foodVotes');
    bool exists = await file.exists();
    if (exists) {
      await file.open();
      String values = await file.readAsString();
      List<List<dynamic>> rowsAsListOfValues =
          CsvToListConverter().convert(values);
      // print("FROM LOCAL: ${rowsAsListOfValues[2]}");

      yield rowsAsListOfValues;
    } else {
      yield [];
    }
  }

  Future<File> _localFile(String range) async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    String filename = tempPath + range + '.csv';
    return File(filename);
  }

  loadFoodIllustrationData() async {
    sheet.getData('FoodItems!A:B').listen((data) {
      data.removeAt(0);
      for (var lst in data) {
        foodIllustration.putIfAbsent(lst[0], () => lst[1]);
      }
      print(foodIllustration);
    });
  }

  loadMessData() async {
    sheet.getData('MessMenu!A:G').listen((data) {
      int num1 = (data[0][0] is int) ? data[0][0] : int.parse(data[0][0]);
      int num2 = (data[0][1] is int) ? data[0][1] : int.parse(data[0][1]);
      int num3 = (data[0][2] is int) ? data[0][2] : int.parse(data[0][2]);
      int num4 = (data[0][3] is int) ? data[0][3] : int.parse(data[0][3]);
      data.removeAt(0);
      makeMessList(data, num1, num2, num3, num4);
      foodCards = [
        FoodCard(
            day: 'Monday',
            breakfast: monday[0],
            lunch: monday[1],
            snacks: monday[2],
            dinner: monday[3]),
        FoodCard(
            day: 'Tuesday',
            breakfast: tuesday[0],
            lunch: tuesday[1],
            snacks: tuesday[2],
            dinner: tuesday[3]),
        FoodCard(
            day: 'Wednesday',
            breakfast: wednesday[0],
            lunch: wednesday[1],
            snacks: wednesday[2],
            dinner: wednesday[3]),
        FoodCard(
            day: 'Thursday',
            breakfast: thursday[0],
            lunch: thursday[1],
            snacks: thursday[2],
            dinner: thursday[3]),
        FoodCard(
            day: 'Friday',
            breakfast: friday[0],
            lunch: friday[1],
            snacks: friday[2],
            dinner: friday[3]),
        FoodCard(
            day: 'Saturday',
            breakfast: saturday[0],
            lunch: saturday[1],
            snacks: saturday[2],
            dinner: saturday[3]),
        FoodCard(
            day: 'Sunday',
            breakfast: sunday[0],
            lunch: sunday[1],
            snacks: sunday[2],
            dinner: sunday[3]),
      ];
      mainPageLoading = false;
      setState(() {});
    });
  }

  bool prevConnected = true;
  PageController _pageController;
  List<String> titles = ["", /*(beta)"News",*/ "Buses", "Campus Map", "Misc"];
  Widget homeScreen() {
    return Scaffold(
      backgroundColor: Colors.white.withAlpha(252),
      extendBodyBehindAppBar: true,
      bottomNavigationBar: BottomNavyBar(
        selectedIndex: selectedIndex,
        showElevation: true,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        onItemSelected: (index) {
          selectedIndex = index;
          _pageController.jumpToPage(index);
          setState(() {});
        },
        items: [
          BottomNavyBarItem(
            icon: Icon(Icons.apps),
            title: Text('Home'),
            activeColor: primaryColor,
            inactiveColor: Colors.grey,
            textAlign: TextAlign.center,
          ),
          /*(beta)BottomNavyBarItem(
            icon: Icon(Icons.rss_feed),
            title: Text('Feed'),
            activeColor: primaryColor,
            inactiveColor: Colors.grey,
            textAlign: TextAlign.center,
          ),*/
          BottomNavyBarItem(
            icon: Icon(Icons.airport_shuttle),
            title: Text('Shuttle'),
            activeColor: primaryColor,
            inactiveColor: Colors.grey,
            textAlign: TextAlign.center,
          ),
          BottomNavyBarItem(
            icon: Icon(Icons.map),
            textAlign: TextAlign.center,
            title: Text('Map'),
            activeColor: primaryColor,
            inactiveColor: Colors.grey,
          ),
          BottomNavyBarItem(
            icon: Icon(Icons.menu),
            title: Text('Misc'),
            textAlign: TextAlign.center,
            activeColor: primaryColor,
            inactiveColor: Colors.grey,
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        leading: Icon(
          Icons.menu,
          color: Colors.transparent,
        ),
        title: Container(
            decoration: new BoxDecoration(
                color: (titles[selectedIndex] == "")
                    ? Colors.transparent
                    : Colors.white.withAlpha(120),
                borderRadius: new BorderRadius.all(Radius.circular(40))),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(titles[selectedIndex],
                  style: TextStyle(
                      color: Colors.black.withAlpha(250),
                      fontWeight: FontWeight.bold)),
            )),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey.withAlpha(100)),
            onPressed: () {
              reloadData();
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app, color: Colors.grey.withAlpha(100)),
            onPressed: () {
              logoutUser().then((value) {
                Navigator.pushReplacementNamed(context, '/signin');
              });
            },
          )
        ],
        // title: Text('Institute App',
        //     style: TextStyle(
        //       fontFamily: 'OpenSans',
        //       // color: Colors.black,
        //       fontSize: 22,
        //     )),
        centerTitle: true,
      ),
      body: PageView(
        physics: new NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => selectedIndex = index);
        },
        children: <Widget>[
          OfflineBuilder(
            connectivityBuilder: (context, connectivity, child) {
              bool connected = connectivity != ConnectivityResult.none;
              if (connected != prevConnected) {
                reloadData();
                print("reloading");
                prevConnected = connected;
              }
              return new SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(height: 60),
                      AnimatedContainer(
                        decoration: new BoxDecoration(
                            color: Color(0xFFEE4400),
                            borderRadius: new BorderRadius.all(
                                const Radius.circular(10.0))),
                        height: (connected) ? 0 : 24,
                        width: 100,
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.linear,
                        child: Center(
                          child: Text(
                            "Offline",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      (connected)
                          ? Container()
                          : SizedBox(
                              height: 10,
                            ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            (currentUser == null)
                                ? Image.asset(
                                    'assets/images/avatar.png',
                                    fit: BoxFit.cover,
                                    width: 90.0,
                                  )
                                : CircleAvatar(
                                    backgroundColor: Colors.transparent,
                                    minRadius: 30,
                                    child: ClipOval(
                                        child: CachedNetworkImage(
                                      fit: BoxFit.cover,
                                      width: 90.0,
                                      placeholder: (context, url) =>
                                          CircularProgressIndicator(),
                                      height: 90.0,
                                      imageUrl: currentUser['picture'],
                                    )),
                                  ),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (currentUser == null)
                                        ? "Hey John Doe!"
                                        : "Hey " +
                                            currentUser['given_name']
                                                .split(' ')[0] +
                                            '!',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    "How are you doing today? ",
                                    style: TextStyle(
                                        color: Colors.black.withAlpha(150)),
                                  ),
                                  // Text(
                                  //   "3 days to the weekend \uf601",
                                  //   style: TextStyle(
                                  //     fontSize: 12.0,
                                  //     fontStyle: FontStyle.italic,
                                  //       color: Colors.black.withAlpha(150)),
                                  // ),
                                ]),
                          ]),
                      SizedBox(height: 30),
                      GestureDetector(
                        onTap: () {
                          return Navigator.pushNamed(context, '/messmenu');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        "Hungry?",
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Here's what's for ${selectMeal(foodCards)['meal'].toLowerCase()}",
                                        style: TextStyle(
                                            color: Colors.black.withAlpha(150)),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.arrow_forward),
                                ],
                              ),
                              SizedBox(height: 10),
                              // CarouselSlider(
                              //   height: 100.0,
                              //   viewportFraction: 0.3,
                              //   enlargeCenterPage: false,
                              //   autoPlay: true,
                              //   items: selectMeal(foodCards)['list']
                              //       .map<Widget>((i) {
                              //     return Builder(
                              //       builder: (BuildContext context) {
                              //         return Container(
                              //           width: 250.0,
                              //           height: 120.0,
                              //           child: Card(
                              //             // color: primaryColor,
                              //             child: Padding(
                              //               padding: const EdgeInsets.all(15.0),
                              //               child: Center(
                              //                 child: Text(
                              //                   i,
                              //                   style: TextStyle(
                              //                       // fontSize: 20.0,
                              //                       ),
                              //                 ),
                              //               ),
                              //             ),
                              //           ),
                              //         );
                              //       },
                              //     );
                              //   }).toList(),
                              // ),
                              // SizedBox(
                              //   height: 20,
                              // ),
                            ],
                          ),
                        ),
                      ),
                      MessMenuBaseDrawer(selectMeal(foodCards), foodIllustration),
                      (twoEvents.length == 0)
                          ? Container()
                          : GestureDetector(
                              onTap: () {
                                return Navigator.pushNamed(
                                    context, '/schedule');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              "Wondering what's next?",
                                              style: TextStyle(
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "Here's your schedule",
                                              style: TextStyle(
                                                  color: Colors.black
                                                      .withAlpha(150)),
                                            ),
                                          ],
                                        ),
                                        Icon(Icons.arrow_forward),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children:
                                          twoEvents.map((EventModel event) {
                                        return scheduleCard(event);
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      /*(beta)GestureDetector(
                        onTap: () {
                          return Navigator.pushNamed(context, '/schedule');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        "Bored?",
                                        style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "Checkout ongoing events",
                                        style: TextStyle(
                                            color: Colors.black.withAlpha(150)
                                            // fontSize: 18.0,
                                            // fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Icon(Icons.arrow_forward),
                                ],
                              ),
                              SizedBox(height: 10),
                              CarouselSlider(
                                height: 300.0,
                                viewportFraction: 1.0,
                                enlargeCenterPage: false,
                                autoPlay: true,
                                items: selectMeal(foodCards)['list']
                                    .map<Widget>((i) {
                                  return Builder(
                                    builder: (BuildContext context) {
                                      return Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        // color: Colors.black,
                                        child: Container(
                                          child: Center(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: <Widget>[
                                                Container(
                                                  // color: Colors.black,
                                                  height: 200.0,
                                                  width: ScreenSize.size.width,
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.only(
                                                      topLeft:
                                                          Radius.circular(10.0),
                                                      topRight:
                                                          Radius.circular(10.0),
                                                    ),
                                                    child: Image(
                                                      fit: BoxFit.cover,
                                                      height: 200.0,
                                                      // width: 300,
                                                      image: NetworkImage(
                                                          'https://assets.entrepreneur.com/content/3x2/2000/20191009140007-GettyImages-1053962188.jpeg'),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  decoration: new BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: new BorderRadius
                                                              .only(
                                                          bottomLeft:
                                                              const Radius
                                                                      .circular(
                                                                  10.0),
                                                          bottomRight:
                                                              const Radius
                                                                      .circular(
                                                                  10.0))),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .fromLTRB(8, 8, 8, 8.0),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      // mainAxisAlignment:
                                                      //     MainAxisAlignment
                                                      //         .spaceAround,
                                                      children: <Widget>[
                                                        SizedBox(width: 10),
                                                        Column(
                                                          children: <Widget>[
                                                            Text("24",
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 20,
                                                                )),
                                                            Text('July')
                                                          ],
                                                        ),
                                                        verticalDivider(),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: <Widget>[
                                                            Text(
                                                                "Photography Contest",
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                )),
                                                            Text("Starts 7pm!",
                                                                style:
                                                                    TextStyle(
                                                                  color: Colors
                                                                      .black
                                                                      .withAlpha(
                                                                          150),
                                                                  // fontWeight:
                                                                  //     FontWeight.bold,
                                                                  // fontSize: 16,
                                                                )),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),*/

                      // RaisedButton(
                      //   child: Text("Feed"),
                      //   onPressed: () {
                      //     Navigator.pushNamed(context, '/feed');
                      //   },
                      // ),
                    ],
                  ),
                ),
              );
            },
            child: Container(),
          ),
          //(beta)FeedPage(),
          Shuttle(),
          MapPage(),
          MiscPage(),
        ],
      ),
    );
  }

  var monday = [];
  var tuesday = [];
  var wednesday = [];
  var thursday = [];
  var friday = [];
  var saturday = [];
  var sunday = [];
  makeMessList(var messDataList, int num1, int num2, int num3, int num4) {
    // num1 : Number of cells in breakfast, num2 : Number of cells in lunch, num3 : Number of cells in snacks, num4 : Number of cells in dinner.
    monday = [];
    tuesday = [];
    wednesday = [];
    thursday = [];
    friday = [];
    saturday = [];
    sunday = [];
    messDataList.removeAt(0);
    messDataList.removeAt(0);
    messDataList.removeAt(num1);
    messDataList.removeAt(num1);
    messDataList.removeAt(num1 + num2);
    messDataList.removeAt(num1 + num2);
    messDataList.removeAt(num1 + num2 + num3);
    messDataList.removeAt(num1 + num2 + num3);

    for (var lm in messDataList) {
      monday += [lm[0]];
      tuesday += [lm[1]];
      wednesday += [lm[2]];
      thursday += [lm[3]];
      friday += [lm[4]];
      saturday += [lm[5]];
      sunday += [lm[6]];
    }

    monday = [monday.sublist(0, num1)] +
        [monday.sublist(num1, num1 + num2)] +
        [monday.sublist(num1 + num2, num1 + num2 + num3)] +
        [monday.sublist(num1 + num2 + num3)];
    tuesday = [tuesday.sublist(0, num1)] +
        [tuesday.sublist(num1, num1 + num2)] +
        [tuesday.sublist(num1 + num2, num1 + num2 + num3)] +
        [tuesday.sublist(num1 + num2 + num3)];
    wednesday = [wednesday.sublist(0, num1)] +
        [wednesday.sublist(num1, num1 + num2)] +
        [wednesday.sublist(num1 + num2, num1 + num2 + num3)] +
        [wednesday.sublist(num1 + num2 + num3)];
    thursday = [thursday.sublist(0, num1)] +
        [thursday.sublist(num1, num1 + num2)] +
        [thursday.sublist(num1 + num2, num1 + num2 + num3)] +
        [thursday.sublist(num1 + num2 + num3)];
    friday = [friday.sublist(0, num1)] +
        [friday.sublist(num1, num1 + num2)] +
        [friday.sublist(num1 + num2, num1 + num2 + num3)] +
        [friday.sublist(num1 + num2 + num3)];
    saturday = [saturday.sublist(0, num1)] +
        [saturday.sublist(num1, num1 + num2)] +
        [saturday.sublist(num1 + num2, num1 + num2 + num3)] +
        [saturday.sublist(num1 + num2 + num3)];
    sunday = [sunday.sublist(0, num1)] +
        [sunday.sublist(num1, num1 + num2)] +
        [sunday.sublist(num1 + num2, num1 + num2 + num3)] +
        [sunday.sublist(num1 + num2 + num3)];
  }

  makeContactList(List importantContactDataList) {
    importantContactDataList.removeAt(0);
    contactCards = [];
    for (List lc in importantContactDataList) {
      contactCards.add(ContactCard(
          name: lc[0], description: lc[1], contacts: jsonDecode(lc[2])));
    }
  }

  List<EventModel> makeListOfTwoEvents() {
    List<EventModel> currentEvents = [];
    DateTime currentTime = DateTime.now();
    if (eventsList != null) {
      eventsList.forEach((EventModel event) {
        print("Event" + event.start.toString());
        if (currentEvents.length < 2) {
          if (event.end.isAfter(currentTime) ||
              event.start.isAfter(currentTime)) {
            currentEvents.add(event);
          }
        }
      });
    }

    return currentEvents;
  }

  Widget scheduleCard(EventModel event) {
    return Card(
      child: Container(
        child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child:
                      Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    time(event.start),
                    SizedBox(
                      height: 8,
                    ),
                    Text("to",
                        style: TextStyle(
                            color: Colors.black.withAlpha(120), fontSize: 14)),
                    SizedBox(
                      height: 8,
                    ),
                    time(event.end),
                  ]),
                ),
                verticalDivider(),
                Expanded(
                  flex: 3,
                  child: descriptionWidget(event),
                ),
              ],
            )),
      ),
    );
  }

  Widget descriptionWidget(EventModel event) {
    // if (event.isCourse || event.isExam) {
    //   return Flexible(
    //     child: Text(event.courseId,
    //         style: TextStyle(
    //             color: Colors.black.withAlpha(120),
    //             fontWeight: FontWeight.bold,
    //             fontSize: 14)),
    //   );
    // } else {
    //   return Flexible(
    //     child: Text(event.description,
    //         style: TextStyle(
    //             color: Colors.black.withAlpha(120),
    //             fontWeight: FontWeight.bold,
    //             fontSize: 14)),
    //   );
    // }
    if (event.isCourse) {
      return Container(
        width: ScreenSize.size.width * 0.55,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(event.courseId,
                  style: TextStyle(
                      color: Colors.black.withAlpha(120),
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              SizedBox(
                height: 8,
              ),
              Flexible(
                fit: FlexFit.loose,
                child: Text(event.courseName,
                    style: TextStyle(
                        color: Colors.black.withAlpha(255),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              SizedBox(
                height: 8,
              ),
              Row(
                children: <Widget>[
                  Text((event.eventType == null) ? 'Course' : event.eventType,
                      style: TextStyle(
                          color: Colors.black.withAlpha(200),
                          fontStyle: FontStyle.italic,
                          fontSize: 14)),
                  SizedBox(
                    width: 8,
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Text('Room: ${event.location}',
                        style: TextStyle(
                            color: Colors.black.withAlpha(200),
                            fontStyle: FontStyle.italic,
                            fontSize: 14)),
                  ),
                ],
              ),
            ]),
      );
    } else if (event.isExam) {
      return Container(
        width: ScreenSize.size.width * 0.55,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(event.courseId,
                  style: TextStyle(
                      color: Colors.black.withAlpha(120),
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              SizedBox(
                height: 8,
              ),
              Text(event.courseName,
                  style: TextStyle(
                      color: Colors.black.withAlpha(255),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              SizedBox(
                height: 8,
              ),
              Row(
                children: <Widget>[
                  Text(event.eventType,
                      style: TextStyle(
                          color: Colors.black.withAlpha(200),
                          fontStyle: FontStyle.italic,
                          fontSize: 14)),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text('Room: ',
                        style: TextStyle(
                            color: Colors.black.withAlpha(200),
                            fontStyle: FontStyle.italic,
                            fontSize: 14)),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Flexible(
                    child: Text('Roll Numbers: ',
                        style: TextStyle(
                            color: Colors.black.withAlpha(200),
                            fontStyle: FontStyle.italic,
                            fontSize: 14)),
                  ),
                ],
              ),
              SizedBox(
                height: 8,
              ),
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(event.location,
                        style: TextStyle(
                            color: Colors.black.withAlpha(200),
                            fontStyle: FontStyle.italic,
                            fontSize: 14)),
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Flexible(
                    child: Text(event.rollNumbers,
                        style: TextStyle(
                            color: Colors.black.withAlpha(200),
                            fontStyle: FontStyle.italic,
                            fontSize: 14)),
                  ),
                ],
              ),
            ]),
      );
    } else {
      return Container(
        width: ScreenSize.size.width * 0.55,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(stringReturn(event.description),
                  style: TextStyle(
                      color: Colors.black.withAlpha(120),
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              SizedBox(
                height: 8,
              ),
              Text(stringReturn(event.summary),
                  style: TextStyle(
                      color: Colors.black.withAlpha(255),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              SizedBox(
                height: 8,
              ),
              Text(
                  stringReturn(event.eventType) +
                      ' (' +
                      stringReturn(event.remarks) +
                      ')',
                  style: TextStyle(
                      color: Colors.black.withAlpha(200),
                      fontStyle: FontStyle.italic,
                      fontSize: 14)),
            ]),
      );
    }
  }

  Widget time(DateTime time) {
    return Text(
        twoDigitTime(time.hour.toString()) +
            ':' +
            twoDigitTime(time.minute.toString()),
        style: TextStyle(color: Colors.black.withAlpha(200), fontSize: 14));
  }

  String twoDigitTime(String text) {
    if (text.length == 1) {
      String _text = '0' + text;
      return _text;
    } else {
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (mainPageLoading == true) {
      return loadScreen();
    } else {
      prepareEventsList();
      twoEvents = makeListOfTwoEvents();
      return WillPopScope(onWillPop: _onBackPressed, child: homeScreen());
    }
  }

  Future<bool> _onBackPressed() {
    if (selectedIndex != 0) {
      _pageController.jumpToPage(0);
    } else {
      SystemNavigator.pop();
    }
  }

  Map selectMeal(List foodList) {
    int day = DateTime.now().weekday - 1;
    int hour = DateTime.now().hour;
    if (hour >= 4 && hour <= 10) {
      return {'meal': 'Breakfast', 'list': foodList[day].breakfast};
    } else if (hour > 10 && hour <= 15) {
      return {'meal': 'Lunch', 'list': foodList[day].lunch};
    } else if (hour > 15 && hour <= 19) {
      return {'meal': 'Snacks', 'list': foodList[day].snacks};
    } else {
      return {'meal': 'Dinner', 'list': foodList[day].dinner};
    }
  }

  List<EventModel> todayExamCourses(List<EventModel> examCourses) {
    List<EventModel> todayExamCourses = [];
    DateTime today = DateTime.now();
    if (examCourses != null) {
      examCourses.forEach((EventModel event) {
        if (event.start.year == today.year &&
            event.start.month == today.month &&
            event.start.day == today.day) {
          todayExamCourses.add(event);
        }
      });
    }
    return todayExamCourses;
  }

  List<EventModel> mergeSameCourses(List<EventModel> currentDayCourses) {
    List<EventModel> _mergedCourses = [];
    bool notHave;

    if (currentDayCourses != null && currentDayCourses.length != 0) {
      for (int i = 0; i < currentDayCourses.length; i++) {
        notHave = true;
        if (i == 0) {
          _mergedCourses.add(currentDayCourses[i]);
        } else {
          _mergedCourses.forEach((EventModel _model) {
            double _modelEndTime = _model.end.hour.toDouble() +
                (_model.end.minute.toDouble() / 60);
            double _courseStartTime =
                currentDayCourses[i].start.hour.toDouble() +
                    (currentDayCourses[i].start.minute.toDouble() / 60);
            double diff = _modelEndTime - _courseStartTime;
            if (diff < 10 &&
                diff > -10 &&
                currentDayCourses[i].courseId == _model.courseId &&
                currentDayCourses[i].courseName == _model.courseName &&
                currentDayCourses[i].remarks == _model.remarks &&
                currentDayCourses[i].eventType == _model.eventType) {
              notHave = false;
              _model.end = currentDayCourses[i].end;
            }
          });
          if (notHave) {
            _mergedCourses.add(currentDayCourses[i]);
          }
        }
      }
    }

    return _mergedCourses;
  }

  String returnText(String text) {
    if (text.length > 2) {
      return text.substring(0, 2);
    } else {
      return text;
    }
  }

  List<EventModel> makeCourseEventModel(
      List<TodayCourse> todayCourses, List<MyCourse> myCourses) {
    List<EventModel> coursesEventModelList = [];

    if (todayCourses != null && todayCourses.length != 0) {
      todayCourses.forEach((TodayCourse todayCourse) {
        if (myCourses != null) {
          myCourses.forEach((MyCourse myCourse) {
            myCourse.lectureCourse.forEach((String text) {
              if (text == todayCourse.course ||
                  text == todayCourse.course.substring(0, 1) ||
                  returnText(text) == todayCourse.course ||
                  returnText(text) == todayCourse.course.substring(0, 1)) {
                if (text.length > 2) {
                  coursesEventModelList.add(EventModel(
                      start: todayCourse.start,
                      end: todayCourse.end,
                      isCourse: true,
                      isExam: false,
                      courseId: myCourse.courseCode,
                      courseName: myCourse.courseName,
                      eventType: 'Lecture ${text.substring(2, text.length)}',
                      location: myCourse.lectureLocation,
                      instructors: myCourse.instructors,
                      credits: myCourse.credits,
                      preRequisite: myCourse.preRequisite,
                      attendanceManager: attendanceData));
                } else {
                  coursesEventModelList.add(EventModel(
                      start: todayCourse.start,
                      end: todayCourse.end,
                      isCourse: true,
                      isExam: false,
                      courseId: myCourse.courseCode,
                      courseName: myCourse.courseName,
                      eventType: 'Lecture',
                      location: myCourse.lectureLocation,
                      instructors: myCourse.instructors,
                      credits: myCourse.credits,
                      preRequisite: myCourse.preRequisite,
                      attendanceManager: attendanceData));
                }
              }
            });
            myCourse.tutorialCourse.forEach((String text) {
              if (text == todayCourse.course ||
                  text == todayCourse.course.substring(0, 1) ||
                  returnText(text) == todayCourse.course ||
                  returnText(text) == todayCourse.course.substring(0, 1)) {
                if (text.length > 2) {
                  coursesEventModelList.add(EventModel(
                      start: todayCourse.start,
                      end: todayCourse.end,
                      isCourse: true,
                      isExam: false,
                      courseId: myCourse.courseCode,
                      courseName: myCourse.courseName,
                      eventType: 'Tutorial ${text.substring(2, text.length)}',
                      location: myCourse.tutorialLocation,
                      instructors: myCourse.instructors,
                      credits: myCourse.credits,
                      preRequisite: myCourse.preRequisite,
                      attendanceManager: attendanceData));
                } else {
                  coursesEventModelList.add(EventModel(
                      start: todayCourse.start,
                      end: todayCourse.end,
                      isCourse: true,
                      isExam: false,
                      courseId: myCourse.courseCode,
                      courseName: myCourse.courseName,
                      eventType: 'Tutorial',
                      location: myCourse.tutorialLocation,
                      instructors: myCourse.instructors,
                      credits: myCourse.credits,
                      preRequisite: myCourse.preRequisite,
                      attendanceManager: attendanceData));
                }
              }
            });
            myCourse.labCourse.forEach((String text) {
              if (text == todayCourse.course ||
                  text == todayCourse.course.substring(0, 1) ||
                  returnText(text) == todayCourse.course ||
                  returnText(text) == todayCourse.course.substring(0, 1)) {
                if (text.length > 2) {
                  coursesEventModelList.add(EventModel(
                      start: todayCourse.start,
                      end: todayCourse.end,
                      isCourse: true,
                      isExam: false,
                      courseId: myCourse.courseCode,
                      courseName: myCourse.courseName,
                      eventType: 'Lab ${text.substring(2, text.length)}',
                      location: myCourse.labLocation,
                      instructors: myCourse.instructors,
                      credits: myCourse.credits,
                      preRequisite: myCourse.preRequisite,
                      attendanceManager: attendanceData));
                } else {
                  coursesEventModelList.add(EventModel(
                      start: todayCourse.start,
                      end: todayCourse.end,
                      isCourse: true,
                      isExam: false,
                      courseId: myCourse.courseCode,
                      courseName: myCourse.courseName,
                      eventType: 'Lab',
                      location: myCourse.labLocation,
                      instructors: myCourse.instructors,
                      credits: myCourse.credits,
                      preRequisite: myCourse.preRequisite,
                      attendanceManager: attendanceData));
                }
              }
            });
          });
        }
      });
    }

    return coursesEventModelList;
  }

  List todayEventsList(List<calendar.Event> _events) {
    List<calendar.Event> todayEvents = [];
    if (_events != null) {
      _events.forEach((calendar.Event _event) {
        bool included = false;
        if (_event.start != null) {
          if (_event.start.dateTime != null) {
            DateTime today = DateTime.now();
            DateTime eventStartTime = _event.start.dateTime;
            if (eventStartTime.year == today.year &&
                eventStartTime.month == today.month &&
                eventStartTime.day == today.day) {
              todayEvents.add(_event);
              included = true;
            }
          }
        }
        if (included == false) {
          if (_event.end != null) {
            if (_event.end.dateTime != null) {
              DateTime today = DateTime.now();
              DateTime eventEndTime = _event.end.dateTime;
              if (eventEndTime.year == today.year &&
                  eventEndTime.month == today.month &&
                  eventEndTime.day == today.day) {
                todayEvents.add(_event);
              }
            }
          }
        }
      });
    }
    return todayEvents;
  }

  int partition(List<EventModel> list, int low, int high) {
    if (list == null || list.length == 0) return 0;
    DateTime pivot = list[high].start;
    int i = low - 1;

    for (int j = low; j < high; j++) {
      if (list[j].start.isBefore(pivot) ||
          list[j].start.isAtSameMomentAs(pivot)) {
        i++;
        swap(list, i, j);
      }
    }
    swap(list, i + 1, high);
    return i + 1;
  }

  void swap(List<EventModel> list, int i, int j) {
    EventModel temp = list[i];
    list[i] = list[j];
    list[j] = temp;
  }

  void quickSort(List<EventModel> list, int low, int high) {
    if (low < high) {
      int pi = partition(list, low, high);
      quickSort(list, low, pi - 1);
      quickSort(list, pi + 1, high);
    }
  }

  @override
  bool get wantKeepAlive => true;
}
