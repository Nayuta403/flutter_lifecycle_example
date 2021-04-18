import 'package:flutter/material.dart';

class PageF extends StatefulWidget {
  PageF({Key key}) : super(key: key);

  @override
  _PageFState createState() => _PageFState();
}

class _PageFState extends State<PageF> {
  int _counter = 0;

  @override
  void initState() {
    logcat("initState");
    super.initState();
  }

  @override
  void dispose() {
    logcat("dispose");
    super.dispose();
  }

  @override
  void deactivate() {
    logcat("deactivate");
    super.deactivate();
  }

  @override
  void didChangeDependencies() {
    logcat("didChangeDependencies");
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(PageF oldWidget) {
    logcat("didUpdateWidget");
    super.didUpdateWidget(oldWidget);
  }

  void _incrementCounter() {}

  @override
  Widget build(BuildContext context) {
    logcat("build");
    return Scaffold(
      appBar: AppBar(
        title: Text('Page F'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

void logcat(String message) {
  debugPrint("lifecycle PageF：$message");
}
