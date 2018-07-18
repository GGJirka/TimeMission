import 'dart:async';
import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/Language.dart';
import 'package:flutter_app/Settings.dart';
import 'package:flutter_app/WifiState.dart';
import 'package:flutter_app/main.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginActivity extends StatelessWidget {

  final String cookie;

  final LanguageManager manager;

  LoginActivity({this.cookie, this.manager});

  /*Save user to preferences and does auto login next time*/
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primaryColor: Colors.orange[800],
      ),
      home: new LoginStateful(
        title: '',
        cookie: cookie,
        manager: manager,
      ),
    );
  }
}

class LoginStateful extends StatefulWidget {
  LoginStateful({Key key, this.title, this.cookie, this.manager})
      : super(key: key);

  final String title;

  final String cookie;

  final LanguageManager manager;

  @override
  _LoginState createState() =>
      new _LoginState(cookie: cookie, manager: manager);
}

/*MAIN CLASSS*/
class _LoginState extends State<LoginStateful> {
  ///Holds current scaffold state
  final key = new GlobalKey<ScaffoldState>();

  String cookie;

  List<ListItem> projects = new List();

  List<ListItem> adProjects = new List();

  LanguageManager manager;

  final TextEditingController descriptionController = new TextEditingController();

  final TextEditingController commentController = new TextEditingController();

  _LoginState({this.cookie, this.manager});

  @override
  void initState() {
    initUser();
    super.initState();
  }

  initUser() async {
    setState(() {
      projects.add(new ListItem(added: true, unfinished: true));
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();

    var day = DateTime.now();

    List<String> daysInWeek = new List();

    List<String> daysNamesInWeek = [
      manager.getWords(23),
      manager.getWords(24),
      manager.getWords(25),
      manager.getWords(26),
      manager.getWords(27)
    ];

    for (int i = 0; i < 5; i++) {
      daysInWeek.add(day
          .add(new Duration(days: -day.weekday + 1 + i))
          .toIso8601String()
          .substring(0, 10));
    }

    String dateFrom = day
        .add(new Duration(days: -day.weekday + 1))
        .toIso8601String()
        .substring(0, 10);

    String dateTo = day
        .add(new Duration(days: 5 - day.weekday))
        .toIso8601String()
        .substring(0, 10);

    if (prefs.getInt("numberOfUnfinishedWorks") == null) {
      prefs.setInt("numberOfUnfinishedWorks", 0);
    }

    if (prefs.getInt("numberOfUnfinishedWorks") > 0) {
      setState(() {
        adProjects.add(new ListItem(
            added: true,
            project: manager.getWords(36),
            unfinished: false,
            uploadAll: true));
      });

      for (int i = 1; i < prefs.getInt("numberOfUnfinishedWorks") + 1; i++) {
        String prefName = "unfinishedWork" + i.toString();
        if (prefs.getStringList(prefName) != null) {
          print(prefName);
          List<String> unfinishedWorks = prefs.getStringList(prefName);
          setState(() {
            adProjects.add(new ListItem(
                date: "3.0",
                time: unfinishedWorks[7],
                timeTo: unfinishedWorks[8],
                project: unfinishedWorks[1],
                hour: "3.0",
                workType: unfinishedWorks[3],
                added: false,
                unfinished: true,
                projectId: int.parse(unfinishedWorks[2]),
                workTypeId: int.parse(unfinishedWorks[5]),
                userId: int.parse(unfinishedWorks[4])));
          });
        }
      }
    }

    var connectivityResult = await (new Connectivity().checkConnectivity());
    try {
      if (connectivityResult == ConnectivityResult.wifi) {
        var requestResponse = await http.get(
            'https://tmtest.artin.cz/data/work-records?filter={"dateFrom":"$dateFrom","dateTo":"$dateTo","userId":205}',
            headers: {"cookie": cookie});

        List data = json.decode(requestResponse.body);

        if (data != null && data.length != 0) {
          for (int i = data.length - 1; i >= 0; i--) {
            /*GET A WORK NAME FROM WORK ID AND BRANCH ID*/
            var id = data[i]['projectId'];
            var workId = data[i]['workTypeId'];

            var work;

            var response2 = await http.get(
                'https://tmtest.artin.cz/data/projects/$id/work-types',
                headers: {"cookie": cookie});

            List workData = json.decode(response2.body);
            work = "";

            if (workData != null && workData.length != 0) {
              for (int j = 0; j < workData.length; j++) {
                if (workData[j]['id'] == workId) {
                work = workData[j]['name'];
                print("founder" + work);
                }
              }
            }

            setState(() {
              /*EXPORT ALL VISIBLE PROJECTS*/
              for (int k = 0; k < daysInWeek.length; k++) {
                if (data[i]['dateFrom'].toString().substring(0, 10) ==
                    daysInWeek[k]) {
                  adProjects.add(new ListItem(
                      added: true,
                      project: daysNamesInWeek[k],
                      unfinished: false));
                  daysInWeek.remove(daysInWeek[k]);
                  daysNamesInWeek.remove(daysNamesInWeek[k]);
                }
              }

              adProjects.add(new ListItem(
                  date: data[i]['hours'].toString(),
                  time: data[i]['dateFrom'].toString(),
                  timeTo: data[i]['dateTo'].toString(),
                  project: data[i]['projectName'],
                  hour: data[i]['hours'].toString(),
                  workType: work.toString(),
                  added: false));
              /*--------------------*/
            });
          }
        }
      }
    } catch (e) {
      print(e);
    }

    setState(() {
      /*END LOADING BAR*/
      projects.removeAt(0);

      for (int i = 0; i < adProjects.length; i++) {
        projects.add(adProjects[i]);
      }
    });
  }

  logout() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.clear();
    Navigator.push(
        context, new MaterialPageRoute(builder: (context) => new MyHomePage()));
  }

  void openSettings() {
    Navigator
        .of(context)
        .push(new MaterialPageRoute(builder: (context) => new SettingsHome()));
  }

  /*DIALOG TO ADD DESCRIPTION AND COMMENT*/
  Future<Null> _addDescription(int index) async {
    return showDialog<Null>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return new AlertDialog(
          content: new SingleChildScrollView(
            child: new ListBody(
              children: <Widget>[
                new Text(
                  manager.getWords(12),
                  style: new TextStyle(fontWeight: FontWeight.bold),
                ),
                new TextField(
                  controller: descriptionController,
                ),
                new Divider(
                  height: 20.0,
                  color: Colors.white,
                ),
                new Text(
                  manager.getWords(32),
                  style: new TextStyle(fontWeight: FontWeight.bold),
                ),
                new TextField(
                  controller: commentController,
                )
              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text(
                manager.getWords(13),
                textScaleFactor: 1.1,
                style: new TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text(
                manager.getWords(14),
                textScaleFactor: 1.1,
                style: new TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                addWork(descriptionController.text, commentController.text,
                    index, false);
              },
            ),
            new FlatButton(
              child: new Text(
                manager.getWords(15),
                textScaleFactor: 1.1,
                style: new TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                index == 0
                    ? addAllWorks("", "")
                    : addWork("", "", index, false);
              },
            ),
          ],
        );
      },
    );
  }

  void addAllWorks(description, comment) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    for (int i = 0;
    i < sharedPreferences.getInt("numberOfUnfinishedWorks");
    i++) {
      addWork(description, comment, 1, true);
    }
  }

  void addWork(description, comment, int index, bool removingAll) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    var data = {
      "id": 474191,
      "projectId": projects[index].projectId,
      "userId": projects[index].userId,
      "description": description,
      "comment": comment,
      "recordType": "W",
      "jiraIssueKey": null,
      "workTypeId": projects[index].workTypeId,
      "dateFrom": projects[index].time,
      "dateTo": projects[index].timeTo,
      "hours": 5.0,
      "subproject": null,
      "jiraWorklogId": null
    };

    var response = await http.post("https://tmtest.artin.cz/data/work-records",
        body: JSON.encode(data),
        headers: {
          "cookie": cookie,
          "Content-type": "application/json;charset=UTF-8"
        });

    setState(() {
      projects.removeAt(index);

      if (preferences.getInt("numberOfUnfinishedWorks") == 1) {
        projects.removeAt(0);
        WifiState.instance.showNotification = false;
      }
    });

    for (int i = index;
    i < preferences.getInt("numberOfUnfinishedWorks");
    i++) {
      String prefName = "unfinishedWork" + i.toString();
      preferences.setStringList(prefName,
          preferences.getStringList("unfinishedWork" + (i + 1).toString()));
    }
    preferences.setInt("numberOfUnfinishedWorks",
        preferences.getInt("numberOfUnfinishedWorks") - 1);

    if (response.statusCode == 200) {
      showToastMessage(manager.getWords(28));
    } else {
      if (json.decode(response.body)['message'] != null) {
        showToastMessage(json.decode(response.body)['message']);
      }
    }
  }

  upload(int index) async {
    if (projects[index].unfinished != null) {
      var connectivityResult = await (new Connectivity().checkConnectivity());

      if (connectivityResult == ConnectivityResult.wifi) {
        _addDescription(index);
      } else {
        showToastMessage("No Internet connection");
      }
    }
  }

  void showToastMessage(String message) {
    key.currentState.showSnackBar(new SnackBar(
      content: new Text(message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: key,
      appBar: new AppBar(
          title: new Text(manager.getWords(7)),
          leading: new IconButton(
              icon: new Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, true);
              })),
      body: new ListView.builder(
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final item = projects[index];
          if (!item.added) {
            return new GestureDetector(
                child: new Card(
                    child: new Padding(
                      padding: new EdgeInsets.all(15.0),
                      child: new Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          new Text(
                            item.project,
                            style: new TextStyle(
                                color: Colors.black.withOpacity(0.6),
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.left,
                            textScaleFactor: 1.1,
                          ),
                          new Row(
                            children: <Widget>[
                              new Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  new Text(
                                    item.workType,
                                    style: new TextStyle(
                                        color: Colors.black.withOpacity(0.4),
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.left,
                                    textScaleFactor: 1.0,
                                  ),
                                  new Text(
                                    item.getDate(),
                                    style: new TextStyle(
                                        color: Colors.black.withOpacity(0.4),
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.left,
                                    textScaleFactor: 1.0,
                                  ),
                                  new Text(
                                    item.getTime(),
                                    style: new TextStyle(
                                        color: Colors.black.withOpacity(0.4),
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.left,
                                    textScaleFactor: 1.0,
                                  ),
                                ],
                              ),
                              new Expanded(
                                child: new Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: <Widget>[
                                    /*new Opacity(
                              opacity: item.unfinished == null ? 1.0 : 0.0,
                              child: new Text(
                                item.getExactHour(),
                                style: new TextStyle(
                                    color: Colors.black.withOpacity(0.4),
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.left,
                                textScaleFactor: 0.9,
                              ),
                            ),*/
                                    new Opacity(
                                      opacity: item.unfinished == null
                                          ? 0.0
                                          : 1.0,
                                      child: new FlatButton(
                                        child: new Text(
                                          manager.getWords(31).toUpperCase(),
                                          textScaleFactor: 1.0,
                                          style: new TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue),
                                        ),
                                        onPressed: () {
                                          upload(index);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )));
          } else {
            if (item.unfinished) {
              return new Center(
                child: new Padding(
                  padding: EdgeInsets.only(top: 150.0),
                  child: new CircularProgressIndicator(),
                ),
              );
            } else {
              return new Padding(
                padding: new EdgeInsets.only(left: 15.0, right: 15.0),
                child: new Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    new Text(
                      item.project,
                      style: new TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                    new Opacity(
                      opacity: item.uploadAll == null ? 0.0 : 1.0,
                      child: new FlatButton(
                        child: new Text(
                          manager.getWords(35),
                          textScaleFactor: 1.0,
                          style: new TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        onPressed: () {
                          upload(index);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }
          }
        },
      ),
    );
  }

/*ADD NEW WORK BASED ON USER DEFAULT VALUES*/
}

class ListItem {
  String date;
  String time;
  String timeTo;
  String project;
  String hour;
  String workType;
  String workTypeName;
  bool added;
  bool uploadAll;
  bool unfinished;
  int projectId;
  int workTypeId;
  int userId;

  ListItem({
    this.date,
    this.time,
    this.timeTo,
    this.project,
    this.hour,
    this.workType,
    this.added,
    this.unfinished,
    this.projectId,
    this.workTypeId,
    this.userId,
    this.uploadAll,
  });

  String getDate() {
    String year = time.substring(0, 4);
    String month = time.substring(5, 7);
    String day = time.substring(8, 10);

    String fDay = day + ". " + month + ". " + year;
    return fDay;
  }

  String getTime() {
    String hour = time.substring(11, 16) + " - " + timeTo.substring(11, 16);
    return hour;
  }

  String setTime() {
    return "Started at " + time.substring(11, 16);
  }

  String getExactHour() {
    if (hour.length <= 3) {
      print(hour.substring(2, 3));
      return hour + "h";
    } else {
      return hour.substring(0, 4) + "h";
    }
  }
}
