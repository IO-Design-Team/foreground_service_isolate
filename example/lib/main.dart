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
    onSendPortReady: (send) {
      IsolateNameServer.removePortNameMapping(isolateName);
      IsolateNameServer.registerPortWithName(send, isolateName);
    },
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
  var dismissible = false;
  var tapAction = NotificationTapAction.launchApp;
  final tapDeepLinkController = TextEditingController(
    text: 'foreground-service-isolate://session/1',
  );
  final tapIntentActionController = TextEditingController(
    text: 'com.iodesignteam.foreground_service_isolate_example.OPEN',
  );

  @override
  void dispose() {
    tapDeepLinkController.dispose();
    tapIntentActionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Foreground Service Isolate')),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<NotificationTapAction>(
                initialValue: tapAction,
                decoration: const InputDecoration(
                  labelText: 'Notification Tap Action',
                  border: OutlineInputBorder(),
                ),
                items: NotificationTapAction.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => tapAction = value);
                },
              ),
              SwitchListTile(
                value: dismissible,
                onChanged: (value) => setState(() => dismissible = value),
                title: const Text('Dismissible Notification'),
                subtitle: const Text(
                  'Turn off to keep foreground notification non-swipeable.',
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              if (tapAction == NotificationTapAction.launchDeepLink)
                TextField(
                  controller: tapDeepLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Tap Deep Link',
                    hintText: 'myapp://session/123',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (tapAction == NotificationTapAction.launchIntentAction)
                TextField(
                  controller: tapIntentActionController,
                  decoration: const InputDecoration(
                    labelText: 'Tap Intent Action',
                    hintText: 'com.example.OPEN_SESSION',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (tapAction != NotificationTapAction.launchApp &&
                  tapAction != NotificationTapAction.none)
                const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(onPressed: spawn, child: const Text('Spawn')),
                  ElevatedButton(
                    onPressed: connect,
                    child: const Text('Connect'),
                  ),
                  ElevatedButton(onPressed: kill, child: const Text('Kill')),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [for (final message in messages) Text(message)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void spawn() async {
    final notificationDetails = buildNotificationDetails();
    if (notificationDetails == null) return;

    connection = await spawnForegroundServiceIsolate(
      isolateEntryPoint,
      notificationDetails: notificationDetails,
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

  NotificationDetails? buildNotificationDetails() {
    String? tapDeepLink;
    String? tapIntentAction;

    if (tapAction == NotificationTapAction.launchDeepLink) {
      tapDeepLink = tapDeepLinkController.text.trim();
      if (tapDeepLink.isEmpty) {
        showError('Tap Deep Link is required for launchDeepLink');
        return null;
      }
    }

    if (tapAction == NotificationTapAction.launchIntentAction) {
      tapIntentAction = tapIntentActionController.text.trim();
      if (tapIntentAction.isEmpty) {
        showError('Tap Intent Action is required for launchIntentAction');
        return null;
      }
    }

    return NotificationDetails(
      channelId: 'foreground_service_isolate',
      channelName: 'Foreground Service Isolate',
      id: 1,
      contentTitle: 'Foreground Service Isolate',
      contentText: 'Running...',
      smallIcon: 'ic_launcher',
      dismissible: dismissible,
      tapAction: tapAction,
      tapDeepLink: tapDeepLink,
      tapIntentAction: tapIntentAction,
    );
  }

  void showError(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
