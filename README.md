# flutter_lifecycle_example

测试 flutter 生命周期和自定义路由功能

## Getting Started

首页包含两个入口，第一个打开跳转PageA，之后继续打开Page B、C、D、E、F 可以在控制台观察日志

第二个入口是自定义路由，可以通过点击右下角按钮进入下一个页面，左上角返回
****

# 庖丁解牛，如何理解 Flutter 路由源码设计？
> 学习最忌盲目，无计划，零碎的知识点无法串成系统。学到哪，忘到哪，面试想不起来。这里我整理了Flutter面试中最常问以及Flutter framework中最核心的几块知识，欢迎关注，共同进步。![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0f9f033174c2428da2d7cd2fdb5374a8~tplv-k3u1fbpfcp-watermark.image)
> 欢迎搜索公众号：**进击的Flutter或者runflutter** 里面整理收集了最详细的Flutter进阶与优化指南。关注我，探讨你的问题，获取我的最新文章~

*本期看点：
1、70行代码实现一个丐版路由 2、路由源码细节解析*

## 导语：
某天在公众号看到这样一个问题

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/f3ae50b01afd4046a67375456931fc85~tplv-k3u1fbpfcp-watermark.image)

这问题我熟啊，刚好翻译 [OverlayEntries 和 Routes 进行了重建优化](https://flutter.cn/docs/release/breaking-changes/overlay-entry-rebuilds) 里面提到，**在 1.17 版本之后，当我们打开一个新页面（Route），前一个页面将不再重新构建**。

啪，我直接一个链接甩出去，潇洒退场。

过了一会儿我再瞅

![WeChated7f093c7bacc883b0b9c87f98952192.png](https://p9-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/1e450bf2498942078c917d236874a06b~tplv-k3u1fbpfcp-watermark.image)

（尴尬而不失礼貌的微笑）所以为了搞清楚**前一个页面为什么build**，我基于 1.12.13 版本写了个    demo 测试，结果发现**不止是前一个页面会再次 build，前面所有的页面都会 build**。 

按常理上一页面被覆盖了就不应该再次构建了！这是发生了什么？要搞清这个问题可还真不那么容易，划分两期来分析原理。本篇会和大家从源码分析一个最熟悉的陌生人**路由**。

***

## 一、初识路由：一种页面切换的能力
为什么先分析路由，因为问题发生在**页面切换的场景**下。

Flutter 中我们往往通过这样一行代码

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/66c25a9f4eab420685ac0c2eae99cbe9~tplv-k3u1fbpfcp-watermark.image)

打开到一个新的页面 PageE，调用 `Navigator.of(context).pop()` 退出一个页面。
所以路由简单来说，就是一种**页面切换的能力**。

Flutter 如何实现这一能力？为了更深刻理解源码设计，本期我们换个思路，让我们抛开现在的路由机制思考：**假如 framework 移除了路由机制，你会如何实现页面切换？**
***

## 二、如何实现一个丐版路由
### 1、设计路由容器
为了管理每个页面的退出和进入，我们可以设计一个路由容器进行管理，那这个容器该如何设计？
观察页面打开和关闭这两个过程，其实非常简单。打开就是目标页面覆盖了上一个页面，而退出过程则刚好相反。

![untitled.gif](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/efb6c8e1b47c4158b73c9fc076d697ad~tplv-k3u1fbpfcp-watermark.image)

根据系统现有的 Widget 我们很自然想到了 **Stack**，Stack 类似原生的相对布局，每个 Widget 可以根据自己的位置叠加显示在屏幕上。只要我们把它的每个子 widget 都撑满，那么 Stack 每次只会显示最后一个 widget，这不就类似**每次打开一个页面**么。


```dart 
class RouteHostState extends State<RouteHost> with TickerProviderStateMixin {
  List<Widget> pages = []; //路由中的多个页面
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand, //每个页面撑满屏幕
      children: pages,
    );
  }
}
```

### 2、提供页面切换方法
因为容器基于 Stack 所以打开和关闭页面也非常简单。对于打开一个页面我们只需要将新的页面添加到 pages 中；关闭页面，我们只要移除最后一个即可。为了让切换过程更加流畅，可以添加一些动画转场效果。

以打开页面为例其实只需三步

#### Step 1、创建一个转场动画
```dart
    //1、创建一个位移动画
    AnimationController animationController;
    Animation<Offset> animation;
    animationController = AnimationController(
          vsync: this, duration: Duration(milliseconds: 500));
    animation = Tween(begin: Offset(1, 0), end: Offset.zero)
          .animate(animationController);
```

#### Step 2、将目标页面添加到 stack 中显示
```dart
    //2、添加到 stack 中并显示
    pages.add(SlideTransition(
      position: animation,
      child: page,
    ));
```

#### Step 3、开启转场动画

```dart
    //3、调用 setState 并开启转场动画
    setState(() {
        animationController.forward();
    }
```

是的，简单来说只需要这三步即可完成，我们可以看看效果
![打开路由.gif](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/0e62d3cd94ea4b0f8290c976f18dd334~tplv-k3u1fbpfcp-watermark.image)

关闭页面则反过来即可。

```dart
 //关闭最后一个页面
  void close() async {
      //出场动画
      await controllers.last.reverse();
      //移除最后一个页面
      pages.removeLast();
      controllers.removeLast().dispose();
  }
}
```


### 3、让子页面使用路由能力
上面我们提到打开关和闭页面方法都在路由容器中，那子页面如何能使用这个能力？这个问题背后其实是 Flutter 中一个很有意思的话题，**父子节点如何数据传递？**。

我们知道 Flutter 框架体系中有三棵树，在[Widget、Element、Render是如何形成树结构？](https://juejin.cn/post/6921493845330886670)中熟悉了它们的构建过程。 Flutter 提供了多个方法让我们可以访问父子节点：
```dart
  abstract class BuildContext {
  ///查找父节点中的T类型的State
  T findAncestorStateOfType<T extends State>();
  ///查找父节点中的T类型的 InheritedWidget 例如 MediaQuery 等
  T dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({ Object aspect })
  ///遍历子元素的element对象
  void visitChildElements(ElementVisitor visitor);
  ......
}
```
源码中例如我们常使用的`Navigator`、`MediaQuery`、`InheritedTheme`，以及很多状态管理框架也是基于这个原理实现。同样的，可以通过这样的方法将路由能力提供给子页面。
```dart
  ///RouteHost提供给子节点访问自己 State 的能力
  static RouteHostState of(BuildContext context) {
    return context.findAncestorStateOfType<RouteHostState>();
  }
  ///子节点借助上面的方法使用路由
  void openPage() {
    RouteHost.of(context).open(RoutePage());
  }  
```

最后我们看看实际打开和关闭的效果：

![完整案例.gif](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/c32938ea3bc64f85b67827d1677ebcfa~tplv-k3u1fbpfcp-watermark.image)

完整案例在 [https://github.com/Nayuta403/flutter_lifecycle_example](https://github.com/Nayuta403/flutter_lifecycle_example);
****

## 三、理解路由源码设计
有了上面的思考，那么对于源码的设计我们就很清晰了。
现在我们回过头来看看路由的使用
```dart
  Navigator.of(context).push(MaterialPageRoute(builder: (c) {
      return PageB();
    }));
```
对比我们设计的路由，来拆解原理。
```dart
  RouteHost.of(context).open(RoutePage());
```
### 路由容器：Navigator
对比两个方法， 其实我们就明白了**Navigator就是起到路由容器的作用**。查看源码你会发现，他被嵌套在 MaterialApp 中，并且 Nagivator 内部也是通过 Stack 实现。


![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/193a7df9fa4d463aaf6a3bb131ce4c5c~tplv-k3u1fbpfcp-watermark.image)

我们的每一个页面都是 Navigator 的子节点，自然可以通过 context 去获取它。
```dart
 static NavigatorState of(BuildContext context) {
    ///获取位于根部的 Navigator
    final NavigatorState navigator = rootNavigator
        ? context.findRootAncestorStateOfType<NavigatorState>()
        : context.findAncestorStateOfType<NavigatorState>();
    return navigator;
  }
```

### Route：处理页面转场等设计
明白了 Navigator 之后，我们发现每次打开页面的时候往往需要传入 `PageRoute` 对象，这又起到什么作用呢？

在我们上面的设计中，为了让过渡自然，我们在 open 方法中，手动的为每一个页面添加了转场动画。
而 Flutter 中将路由切换所需的动画，交互阻断等封装成了 Route 对象。通过层次封装的形式，逐层实现了这些能力：

![image.png](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/39521ae34e0341fc908f0745d71262f4~tplv-k3u1fbpfcp-watermark.image)

有了前面的思考之后，再看路由源码的设计，思路其实变得非常清晰。**对于源码的学习，千万不要一开始深陷在细节中，从整体思考再拆解流程，这样方可深入浅出。**
***
## 四、源码中的亿点点细节

有了整体大框架之后，我们可以具体梳理 `Navigator.of(context).push` 过程。

```dart
  Future<T> push<T extends Object>(Route<T> route) {
    final Route<dynamic> oldRoute = _history.isNotEmpty ? _history.last : null;
    /// 1、新页面的路由进行添加
    route._navigator = this;
    route.install(_currentOverlayEntry); ///关键方法！！！！！！！
    _history.add(route);
    route.didPush();
    route.didChangeNext(null);
    /// 2、上一个路由的相关回调
    if (oldRoute != null) {
      oldRoute.didChangeNext(route);
      route.didChangePrevious(oldRoute);
    }
    /// 3、回调 Navigator 的观察者
    for (NavigatorObserver observer in widget.observers)
      observer.didPush(route, oldRoute);
    RouteNotificationMessages.maybeNotifyRouteChange(_routePushedMethod, route, oldRoute);
    _afterNavigation(route);
    return route.popped;
  }
```
这里我们只需关注核心的第一个过程，关键方法在：
```dart
   route.install(_currentOverlayEntry); 
```
这个方法被 Route 的子类重写，并且分层完成了不同逻辑：
![image.png](https://p3-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/eda1b9b6c2474977bba87da2e59955c7~tplv-k3u1fbpfcp-watermark.image)

在OverlayRoute中如下：
```dart
  void install(OverlayEntry insertionPoint) {
    /// 通过 createOverlayEntries() 创建新页面的 _overlayEntries 集合
    /// 这个 _overlayEntries 集合就是我们打开的新页面
    _overlayEntries.addAll(createOverlayEntries());
    /// 将新页面的 _overlayEntries 集合插入到 overlay 中显示
    navigator.overlay?.insertAll(_overlayEntries, above: insertionPoint);
    super.install(insertionPoint);
  }
  
  Iterable<OverlayEntry> createOverlayEntries() sync* {
    /// 创建一个遮罩
    yield _modalBarrier = OverlayEntry(builder: _buildModalBarrier);
    /// 创建页面实际内容，最终调用到 Route 的 builder 方法
    yield OverlayEntry(builder: _buildModalScope, maintainState: maintainState);
  }
```

第一行代码中的 `createOverlayEntries()` 方法会先创建一个zhe调用到 Route 的 builder 方法，创建我们需要打开的页面与遮罩，之后将整个集合添加到 Overlay 中（如果不太熟悉 Overlay 将它当做一个 Stack 就行）。

```dart
/// overlay.dart
void insertAll(Iterable<OverlayEntry> entries, { OverlayEntry below, OverlayEntry above }) {
    setState(() {
      _entries.insertAll(_insertionIndex(below, above), entries);
    });
  }
```
overlay 的方法也很简单，添加页面到 `_entries` 调用 setState() 更新。 这个 `_entries` 简单来看，这个 `_entries` 就和我们前面设计的 `pages` 类似，不过里面多了 **选择渲染** 的能力，我们下一期再详细分析。
***
## 五、总结
看到这，相信你对于 Flutter 中的路由再也不会感到陌生，总结下来关键有三点：
* **1、Navigator 作为路由容器内部嵌套了 Stack 提供了页面切换的能力。**
* **2、通过context.findRootAncestorStateOfType<T>()可以访问父节点**
* **3、Route 为我们封装了切换时需要的其他能力**
***
## 六、最后 感谢各位吴彦祖和彭于晏的点赞,Start,和Follow

当我们切换页面的时候，上一个页面默认会走以下几个生命周期：

![image.png](https://p6-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/b5f3852d39664f4a8cbde1ac927f424e~tplv-k3u1fbpfcp-watermark.image)

这又是为什么？一定是这样的顺序么？Flutter 生命周期到底改怎么回答？ 我们留着下一期再分析拉~

如果你觉得文章写得还不错~ 点个关注、点个赞啦~

欢迎搜索公众号：进击的Flutter或者runflutter 里面整理收集了最详细的Flutter进阶与优化指南。关注我，获取我的最新文章~
