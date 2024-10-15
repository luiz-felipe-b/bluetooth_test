import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:teste_bluetooth_pi/MessageController.dart';
import 'package:teste_bluetooth_pi/models/message.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({super.key, required this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _ChatPage extends State<ChatPage> {
  static const clientID = 0;
  BluetoothConnection? connection;

  MessageController messageController = new MessageController();
  List<Message> messages = List<Message>.empty(growable: true);
  String _messageBuffer = '';

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);

  bool isDisconnecting = false;

  Message temporaryItem = new Message(
      34566,
      'Quando algum RFID for lido pelo leitor, ele aparecerá nesta mesma caixa como exemplo. '
          'Vale mencionar que valores com uma sequência de zeros indicam falha na leitura'
  );
  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
        messages.add(temporaryItem);
      });

      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);

      setState(() {
        isConnecting = false;
      });
    });
  }

  @override
  void dispose() {

    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    if(messages.isNotEmpty) {
      sendMessages(messages);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Row> list = messages.map((_message) {
      return Row(
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 222.0,
            decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(7.0)),
            child: Text(
                (text) {
                  return text == '/shrug' ? '' : text;
                }(_message.text.trim()),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      );
    }).toList();

    final serverName = widget.server.name ?? "Unknown";
    return Scaffold(
      appBar: AppBar(
          title: (isConnecting
              ? Text('Conectando com $serverName...')
              : isConnected
                  ? Text('Conexão com $serverName')
                  : const Text('Conexão Perdida')
          ),
          backgroundColor: const Color.fromRGBO(0, 20, 137, 1),
          foregroundColor: Colors.white,
      ),
      body:isConnecting
          ? Center(
              child: Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0)),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.4,
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(
                        width: 70.0,
                        height: 70.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 6.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(0, 20, 137, 1),),
                          // Cor opcional
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text(
                        'Conectando-se ao dispositivo $serverName',
                        style: const TextStyle(fontSize: 25),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : isConnected?
              SafeArea(
                child: Column(
                  children: <Widget>[
                    Flexible(
                      child: ListView(
                          padding: const EdgeInsets.all(12.0),
                          controller: listScrollController,
                          children: list),
                    )
                  ],
                ),
              )
          : Center(
        child: Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.4,
                  maxHeight: 500
              ),
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.cloud_off_outlined, color: Colors.red, size: 80),
                  const SizedBox(height: 15),
                  Text(
                    messages.isNotEmpty ?
                      'Conexão perdida com $serverName, mas não se preocupe, qualquer dado emitido pelo leitor foi salvo!' :
                      'Não foi possível conectar-se com $serverName',

                    style: const TextStyle(fontSize: 25,),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      )

    );
  }

  void sendMessages(List<Message> messages) {
    messageController.sendObtainedMessages(filterMessages(messages));
  }

  List<Message> filterMessages(List<Message> messages) {
    List<Message> messagesWithOnlyId = messages.map((message) {
      int commaIndex = message.text.indexOf(',');
      if (commaIndex != -1) {
        message.text = message.text.substring(0, commaIndex);
      }
      return message;
    }).toList();

    List<Message> filteredMessages = messagesWithOnlyId
        .where((message) => !message.text.contains('00000000'))
        .toList();

    return filteredMessages.toSet().toList();
  }
  // Função de conversão dos dados recebidos
  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        if(messages.first == temporaryItem) {
          messages.remove(temporaryItem);
        }
        messages.add(
          Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
          0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }
}
