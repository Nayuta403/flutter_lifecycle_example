import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lifecycle_example/pageA.dart';
import 'package:flutter_lifecycle_example/route_design.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('lifecycle example')),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('打印生命周期'),
            onTap: () => open(PageA()),
          ),
          ListTile(
            title: Text('丐版路由'),
            onTap: () => open(RouteHost()),
          )
        ],
      ),
    );
  }

  open(Widget page) {
    Navigator.of(context).push(CupertinoPageRoute(builder: (c) {
      return page;
    }));
  }
}
