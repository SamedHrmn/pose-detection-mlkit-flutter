import 'package:flutter/material.dart';
import 'package:flutter_mlkit_platform_channel/channel_helper.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Material App', home: HomeView());
  }
}

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Material App Bar'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await ChannelHelper.startAndroidPoseDetectionWithChannel();
          },
          child: Text("Start MLKit"),
        ),
      ),
    );
  }
}
