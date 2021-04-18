import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_lifecycle_example/pageA.dart';

class RouteHost extends StatefulWidget {
  @override
  RouteHostState createState() => RouteHostState();

  static RouteHostState of(BuildContext context) {
    return context.findAncestorStateOfType<RouteHostState>();
  }
}

class RouteHostState extends State<RouteHost> with TickerProviderStateMixin {
  List<AnimationController> controllers = [];

  List<Widget> pages = []; //路由中的多个页面
  @override
  void initState() {
    super.initState();
    //初始化路由
    pages.add(RoutePage());
    controllers.add(AnimationController(vsync: this));
  }

  @override
  void dispose() {
    controllers.forEach((e) => e.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand, //每个页面撑满屏幕
      children: pages,
    );
  }

  void open(Widget page) {
    setState(() {
      //1、创建一个位移动画
      AnimationController animationController;
      Animation<Offset> animation;
      animationController = AnimationController(
          vsync: this, duration: Duration(milliseconds: 500));
      animation = Tween(begin: Offset(1, 0), end: Offset.zero)
          .animate(animationController);
      controllers.add(animationController);

      //2、添加到 stack 中并显示
      pages.add(SlideTransition(
        position: animation,
        child: page,
      ));
      //3、开启转场动画
      animationController.forward();
    });
  }

  //关闭最后一个页面
  void close() async {
    try {
      //出场动画
      await controllers.last.reverse();
      pages.removeLast();
      controllers.removeLast().dispose();
    } catch (e) {
      Navigator.of(context).pop();
    }
  }
}

class RoutePage extends StatefulWidget {
  RoutePage({Key key}) : super(key: key);

  @override
  _RoutePageState createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.blue,
    Colors.black,
    Colors.purple,
    Colors.tealAccent
  ];

  void openPage() {
    RouteHost.of(context).open(RoutePage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('测试的Route页面'),
        leading: BackButton(
          onPressed: () {
            RouteHost.of(context).close();
          },
        ),
      ),
      body: Center(
        child: Container(
          height: 300,
          width: 300,
          color: colors[Random().nextInt(6)],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openPage,
        tooltip: '打开一个新页面',
        child: Icon(Icons.open_in_browser),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
