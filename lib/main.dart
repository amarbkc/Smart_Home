
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/src/typed_buffer.dart';

final String broker = 'fe9cc652a75744b99492d75f8ba5b6b2.s1.eu.hivemq.cloud';
final int port = 8883;
final String username = 'amarkc';
final String password = 'Amarkc9702';
String messagetosend = "";
String topic = " ";




void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartHome',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<RoomCard> roomCards = [
    RoomCard(roomName: 'Bedroom 1', numberOfSwitches: 2, switchNames: ['Light', 'Fan']),
    RoomCard(roomName: 'Bedroom 2', numberOfSwitches: 2, switchNames: ['Light', 'Fan']),
    RoomCard(roomName: 'Kitchen', numberOfSwitches: 3, switchNames: ['Light', 'Fan', 'Oven']),
    RoomCard(roomName: 'Living Room', numberOfSwitches: 3, switchNames: ['Light', 'Fan', 'TV']),
    RoomCard(roomName: 'Store Room', numberOfSwitches: 2, switchNames: ['Light', 'Shelves']),
  ];

  TextEditingController roomNameController = TextEditingController();
  TextEditingController numberOfSwitchesController = TextEditingController();
  TextEditingController switchNamesController = TextEditingController();
  TextEditingController deletePasswordController = TextEditingController();

  void addRoomCard() {
    String newRoomName = roomNameController.text;
    int newNumberOfSwitches = int.tryParse(numberOfSwitchesController.text) ?? 2;
    List<String> newSwitchNames = switchNamesController.text.split(',').map((e) => e.trim()).toList();

    if (newRoomName.isNotEmpty && newSwitchNames.length == newNumberOfSwitches) {
      setState(() {
        roomCards.add(RoomCard(
          roomName: newRoomName,
          numberOfSwitches: newNumberOfSwitches,
          switchNames: newSwitchNames,
        ));

        // Clear the text fields
        roomNameController.clear();
        numberOfSwitchesController.clear();
        switchNamesController.clear();
      });
    }
  }

  Future<void> deleteRoom(int index) async {
    bool passwordConfirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Password to Delete Room'),
          content: TextField(
            controller: deletePasswordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel, password not confirmed
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (deletePasswordController.text == '9702') {
                  Navigator.of(context).pop(true); // Confirm, password correct
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Incorrect password. Room not deleted.'),
                    ),
                  );
                  deletePasswordController.clear(); // Clear the password field
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (passwordConfirmed != null && passwordConfirmed) {
      setState(() {
        roomCards.removeAt(index);
        deletePasswordController.clear(); // Clear the password field
      });
    }else{
      setState(() {
        _HomeScreenState();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Home Control'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Add a New Room'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: roomNameController,
                          decoration: InputDecoration(labelText: 'Room Name'),
                        ),
                        TextField(
                          controller: numberOfSwitchesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Number of Switches (default: 2)',
                          ),
                        ),
                        TextField(
                          controller: switchNamesController,
                          decoration: InputDecoration(labelText: 'Switch Names (comma-separated)'),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          addRoomCard();
                          Navigator.of(context).pop();
                        },
                        child: Text('Add'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body:Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue, Colors.purple], // Adjust gradient colors here
          ),
        ),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Number of columns in the grid
            childAspectRatio: MediaQuery.of(context).size.width /
                (MediaQuery.of(context).size.height/2),// Aspect ratio for each card
          ),
          itemCount: roomCards.length,
          itemBuilder: (context, index) {
            return Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.endToStart,
              onDismissed: (direction) {
                deleteRoom(index);
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20.0),
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              child: roomCards[index],
            );
          },
        ),
      ),
    );
  }
}

class RoomCard extends StatefulWidget {
  final String roomName;
  final int numberOfSwitches;
  final List<String> switchNames;

  RoomCard({
    required this.roomName,
    required this.numberOfSwitches,
    required this.switchNames,
  });

  @override
  _RoomCardState createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  List<bool> switchValues = [];

  @override
  void initState() {
    super.initState();
    // Initialize switchValues with all switches turned off
    for (int i = 0; i < widget.numberOfSwitches; i++) {
      switchValues.add(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(5.0),
            child: Text(
              widget.roomName,
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
          ),
          for (int i = 0; i < widget.numberOfSwitches; i++)
            ListTile(
              title: Text(
                widget.switchNames[i],
                style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.normal),
              ),
              trailing: Switch(
                value: switchValues[i],
                onChanged: (newValue) {
                  setState(() {
                    messagetosend = newValue.toString();
                    topic = widget.roomName.toString().replaceAll(' ', '').toLowerCase()+'/'+widget.switchNames[i].toString().replaceAll(' ', '').toLowerCase();
                    try {
                      MQTTClientWrapper newclient = new MQTTClientWrapper();
                      newclient.prepareMqttClient();
                    } catch (e) {
                      print('Error: $e');
                    }
                    switchValues[i] = newValue;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}






enum MqttCurrentConnectionState {
  IDLE,
  CONNECTING,
  CONNECTED,
  DISCONNECTED,
  ERROR_WHEN_CONNECTING
}

class MQTTClientWrapper {

  late MqttServerClient client;

  MqttCurrentConnectionState connectionState = MqttCurrentConnectionState.IDLE;

  // using async tasks, so the connection won't hinder the code flow
  void prepareMqttClient() async {
    _setupMqttClient();
    await _connectClient();
    _publishMessage(messagetosend);
  }

  // waiting for the connection, if an error occurs, print it and disconnect
  Future<void> _connectClient() async {
    try {
      print('client connecting....');
      connectionState = MqttCurrentConnectionState.CONNECTING;
      await client.connect(username, password);
    } on Exception catch (e) {
      print('client exception - $e');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }

    // when connected, print a confirmation, else print an error
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      connectionState = MqttCurrentConnectionState.CONNECTED;
      print('client connected');
    } else {
      print(
          'ERROR client connection failed - disconnecting, status is ${client.connectionStatus}');
      connectionState = MqttCurrentConnectionState.ERROR_WHEN_CONNECTING;
      client.disconnect();
    }
  }

  void _setupMqttClient() {
    client = MqttServerClient.withPort(broker, '<anil>', port);
    // the next 2 lines are necessary to connect with tls, which is used by HiveMQ Cloud
    client.secure = true;
    client.securityContext = SecurityContext.defaultContext;
    client.keepAlivePeriod = 20;
    client.onDisconnected = _onDisconnected;
    client.onConnected = _onConnected;
  }



  void _publishMessage(String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    print('Publishing message "$message" to topic ${topic}');
    client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload as Uint8Buffer);

  }



  void _onDisconnected() {
    print('OnDisconnected client callback - Client disconnection');
    connectionState = MqttCurrentConnectionState.DISCONNECTED;
  }

  void _onConnected() {
    connectionState = MqttCurrentConnectionState.CONNECTED;
    print('OnConnected client callback - Client connection was sucessful');
  }

}
