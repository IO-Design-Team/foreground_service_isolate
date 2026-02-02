import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:foreground_service_isolate/foreground_service_isolate.dart';
import 'package:permission_handler/permission_handler.dart';

const eventChannelId = 'foreground_service_isolate_event';
const isolateName = 'foreground_service_isolate';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Permission.notification.request();

  runApp(const ExampleApp());
}

@pragma('vm:entry-point')
void isolateEntryPoint(SendPort? send) {
  final connection = setupIsolate(
    send,
    onSendPortReady: (send) =>
        IsolateNameServer.registerPortWithName(send, isolateName),
  );

  final stream = Stream<String>.periodic(
    const Duration(seconds: 1),
    (i) => 'Hello from the isolate: $i',
  ).asBroadcastStream();

  () async {
    while (true) {
      await Future.delayed(const Duration(seconds: 1));

      // This is an example
      // ignore: avoid_print
      print('Isolate is running...');
    }
  }();

  final eventChannel = IsolateEventChannel(eventChannelId, connection);
  eventChannel.setStreamHandler(
    IsolateStreamHandler.inline(
      onListen: (_, sink) => stream.listen(sink.success),
    ),
  );
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<StatefulWidget> createState() => ExampleAppState();
}

class ExampleAppState extends State<ExampleApp> {
  IsolateConnection? connection;
  final messages = <String>[];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Foreground Service Isolate')),
        body: Column(
          children: [
            ElevatedButton(onPressed: spawn, child: const Text('Spawn')),
            ElevatedButton(onPressed: connect, child: const Text('Connect')),
            ElevatedButton(onPressed: kill, child: const Text('Kill')),
            Expanded(
              child: ListView(
                children: [for (final message in messages) Text(message)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void spawn() async {
    connection = await spawnForegroundServiceIsolate(
      isolateEntryPoint,
      notificationDetails: const NotificationDetails(
        channelId: 'foreground_service_isolate',
        channelName: 'Foreground Service Isolate',
        id: 1,
        contentTitle: 'Foreground Service Isolate',
        contentText: 'Running...',
        smallIcon: 'ic_launcher',
      ),
    );
    stream();
  }

  void connect() async {
    if (connection != null) return;

    final send = IsolateNameServer.lookupPortByName(isolateName);
    if (send == null) return;

    connection = await connectToIsolate(send);
    stream();
  }

  void kill() {
    final connection = this.connection;
    if (connection == null) return;

    connection.close();
    this.connection = null;

    ForegroundServiceIsolate.stopService();
  }

  void stream() {
    final connection = this.connection;
    if (connection == null) return;

    final eventChannel = IsolateEventChannel(eventChannelId, connection);
    eventChannel.receiveBroadcastStream().listen(
      (e) => setState(() => messages.insert(0, e)),
    );
  }
}
