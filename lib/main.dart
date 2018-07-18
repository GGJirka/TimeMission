import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/Language.dart';
import 'package:flutter_app/WifiState.dart';
import 'package:flutter_app/WorkState.dart';
import 'package:flutter_string_encryption/flutter_string_encryption.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primaryColor: Colors.orange[800],
      ),
      home: new MyHomePage(
        title: 'Time Mission',
        changeUser: false,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.changeUser}) : super(key: key);

  final String title;

  final bool changeUser;

  @override
  _MyHomePageState createState() =>
      new _MyHomePageState(changeUser: changeUser);
}

class _MyHomePageState extends State<MyHomePage> {

  ///KEY - HOLDS SCAFFOLD STATE
  final key = new GlobalKey<ScaffoldState>();

  final loginController = new TextEditingController();

  final passwordController = new TextEditingController();

  String loginUser, loginPass;

  bool _remember = true;

  bool changeUser;

  LanguageManager manager = new LanguageManager();

  _MyHomePageState({@required this.changeUser});

  @override
  void initState() {
    manager.setLanguage();
    checkForLoggedUser();
    super.initState();
  }

  /*CHECKS IF USER IS ALREADY LOGGED IN*/
  checkForLoggedUser() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    final crypto = new PlatformStringCryptor();

    //AES key arg1 - password to key, arg2 - salt
    final String key = await crypto.generateKeyFromPassword(
        "artin_the_best", "salt");

    /*If there is more than 0 unfinished works shows notification*/
    if (sharedPreferences.getInt("numberOfUnfinishedWorks") != null) {
      if (sharedPreferences.getInt("numberOfUnfinishedWorks") > 0) {
        WifiState.instance.showNotification = true;
      }
    }

    if (sharedPreferences.getString('username') != "" &&
        sharedPreferences.getString('username') != null) {
      loginUser = sharedPreferences.getString('username');

      try {
        //decrypt password
        loginPass =
        await crypto.decrypt(sharedPreferences.getString('password'), key);
      } on MacMismatchException {

      }
      loginController.text = loginUser;
      passwordController.text = loginPass;
      _remember = true;
    }

    if (loginUser != "" && loginUser != null && loginPass != "" &&
        loginPass != null) {
      fetchPost(loginUser, loginPass);
    }
  }

  /*POST METHOD - LOGIN*/
  fetchPost(String username, String password) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    final crypto = new PlatformStringCryptor();

    //AES key arg1 - password to key, arg2 - salt
    final String key = await crypto.generateKeyFromPassword(
        "artin_the_best", "salt");


    if (!changeUser) {
      showLoadingDialog();
    }
    var sharedCookie = sharedPreferences.getString("cookie");

    var connectivityResult = await (new Connectivity().checkConnectivity());

    /*CHECKS FOR INTERNET CONNECTION*/
    if (connectivityResult == ConnectivityResult.wifi) {
      var responseTest = await http.get(
          'https://tmtest.artin.cz/data/main/user',
          headers: {"cookie": sharedCookie});

      if (responseTest.statusCode == 401) {
        sharedPreferences.setString("cookie", "");
      }

      /*CHECK IF USER HAS ACTIVE COOKIE
      * IF SO THEN THE LOGIN IS NOT NEEDED*/
      if (sharedCookie == "" || sharedCookie == null) {
        var response = await http.post("https://tmtest.artin.cz/login", body: {
          "username": username,
          "password": password,
          "remember-me": "on"
        }, headers: {
          "content-type": "application/x-www-form-urlencoded"
        });
        pop();

        /*CHECK IF USERNAME AND PASSWORD ARE CORRECT*/
        if (response.statusCode != 500) {
          /*CORRECT*/
          var cookie = response.headers['set-cookie'];

          var responseTest2 = await http.get(
              'https://tmtest.artin.cz/data/main/user',
              headers: {"cookie": cookie});

          if (responseTest2.statusCode != 401) {
            if (_remember) {
              //Store cookie
              sharedPreferences.setString("cookie", cookie);

              //Store username
              sharedPreferences.setString('username', username);

              //encrypt password via AES
              final String pass = await crypto.encrypt(password, key);

              //store password
              sharedPreferences.setString('password', pass);
            }

            startWorkActivity(cookie);
          } else {
            pop();
            myDialog(manager.getWords(16));
          }
        } else {
          /*INCORRECT*/
          myDialog(manager.getWords(17));
        }
      } else {
        pop();
        startWorkActivity(sharedPreferences.getString("cookie"));
      }
    } else {
      pop();
      showToastMessage("No Internet connection");
    }
  }

  /*If login was successful, this starts the work activity*/
  void startWorkActivity(cookie) {
    pop();
    Navigator.pushReplacement(
        context,
        new MaterialPageRoute(
            builder: (context) =>
            new WorkActivity(cookie: cookie, manager: manager)));
  }

  /* Return back to the previous widget
  * if there is a new one that can be destroyed*/
  void pop() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /*Dialog with custom text*/
  Future myDialog(text) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return new AlertDialog(
          content: new Text(text),
        );
      },
    );
  }

  /*shows loading dialog.*/
  void showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      child: new Dialog(
        child: new Padding(
          padding: new EdgeInsets.only(
              top: 20.0, bottom: 20.0, right: 0.0, left: 0.0),
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new CircularProgressIndicator(),
              new Divider(
                height: 20.0,
                color: Colors.white,
              ),
              new Text(
                "Loading",
                style: new TextStyle(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _rememberChange(bool value) {
    setState(() {
      _remember = value;
    });
  }

  void showToastMessage(String message) {
    key.currentState.showSnackBar(new SnackBar(
      content: new Text(message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: this.key,
      appBar: new AppBar(
        centerTitle: true,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      //UI for login
      body: new Center(
        child: new FractionallySizedBox(
          widthFactor: 0.7,
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Theme(
                data: new ThemeData(
                  primaryColor: Colors.orange[700],
                  hintColor: Colors.black,
                  //textSelectionColor: Colors.orange[700],
                ),
                child: new TextField(
                  decoration: new InputDecoration(
                    labelText: "Username", //.getWords(19)
                  ),
                  controller: loginController,
                ),
              ),
              new Theme(
                data: new ThemeData(
                  primaryColor: Colors.orange[700],
                  hintColor: Colors.black,
                  //textSelectionColor: Colors.orange[700],
                ),
                child: new TextField(
                  obscureText: true,
                  decoration: new InputDecoration(
                    labelText: "password",
                  ),
                  controller: passwordController,
                ),
              ),
              new Divider(
                height: 5.0,
                color: Colors.white,
              ),
              new Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  new Checkbox(
                      value: _remember,
                      onChanged: (bool value) {
                        _rememberChange(value);
                      }),
                  new Text(/*manager.getWords(21)*/
                      "Remember me"),
                ],
              ),
              new Container(
                width: double.INFINITY,
                child: new RaisedButton(
                  child: Text(/*manager.getWords(22)*/ "Login"),
                  color: Colors.orange[700],
                  splashColor: Colors.orangeAccent,
                  textColor: Colors.white,
                  onPressed: () {
                    fetchPost(loginController.text, passwordController.text);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
