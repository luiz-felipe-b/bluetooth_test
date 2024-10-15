import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import './ChatPage.dart';
import './DiscoveryPage.dart';
import './SelectBondedDevicePage.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPage createState() => _MainPage();
}

class _MainPage extends State<MainPage> {

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  bool bluetoothConnectPermission = false;
  bool locationPermission = false;
  bool bluetoothScanPermission = false;

  @override
  void initState() {
    super.initState();

    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(const Duration(milliseconds: 0xDD));
      return true;
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

      });
    });

    Permission.bluetoothConnect.isGranted.then((value) => {
      bluetoothConnectPermission = value
    });

    Permission.location.isGranted.then((value) => {
      locationPermission = value
    });

    Permission.bluetoothScan.isGranted.then((value) => {
      bluetoothScanPermission = value
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metro Safe'),
        foregroundColor: Colors.white,
        backgroundColor: Color.fromRGBO(0, 20, 137, 1),
      ),
      body: ListView(
        children: <Widget>[
          const ListTile(
              title: Text('Dispositivos por perto e conexão', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),),
              subtitle: Text(
                  'Certifique-se que todos os tipos de acessos mencionados abaixo foram liberados'
              )
          ),
          const SizedBox(height: 10,),
          ListTile(
            title: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    foregroundColor: const Color.fromRGBO(0, 20, 137, 1)
                ),
                onPressed: (_bluetoothState.isEnabled && locationPermission && bluetoothScanPermission && bluetoothConnectPermission)
                    ? () async {
                  final BluetoothDevice? selectedDevice =
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return const DiscoveryPage();
                      },
                    ),
                  );

                  if (selectedDevice != null) {
                    print('Descoberta -> selecionado ${selectedDevice.address}');
                    _startChat(context, selectedDevice);
                  } else {
                    print('Descoberta -> nenhum aparelho conectado');
                  }
                }
                    : null,
                child: const Text('Explorar dispositvos por perto')),
          ),
          ListTile(
            title: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  foregroundColor: const Color.fromRGBO(0, 20, 137, 1)
              ),
              onPressed: (_bluetoothState.isEnabled && locationPermission && bluetoothScanPermission && bluetoothConnectPermission)
                  ? () async {
                final BluetoothDevice? selectedDevice =
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) {
                      return const SelectBondedDevicePage(checkAvailability: false);
                    },
                  ),
                );

                if (selectedDevice != null) {
                  print('Connect -> selected ${selectedDevice.address}');
                  _startChat(context, selectedDevice);
                } else {
                  print('Connect -> no device selected');
                }
              }
                  : null,
              child: const Text('Conectar-se a aparelho já pareado'),
            ),
          ),
          const Divider(),
          const ListTile(title: Text('Bluetooth', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),)),
          SwitchListTile(
            title: const Text('Uso do Bluetooth'),
            value: _bluetoothState.isEnabled && bluetoothConnectPermission,
            activeColor: Colors.white,
            activeTrackColor: const Color.fromRGBO(51, 177, 20, 1.0),
            onChanged: (bool value) {
              future() async {
                if (!bluetoothConnectPermission) {
                  await Permission.bluetoothConnect.request();
                  await FlutterBluetoothSerial.instance.requestEnable();
                  if(await Permission.bluetoothConnect.isGranted) {
                    setState(() {
                      bluetoothConnectPermission = true;
                    });
                    return;
                  }
                  setState(() {
                    bluetoothConnectPermission = false;
                  });
                  return;
                } else {
                  await FlutterBluetoothSerial.instance.requestDisable();
                  setState(() {
                    bluetoothConnectPermission = false;
                  });
                }

              }
              future();
            },
          ),
          ListTile(
            title: const Text('Status do Bluetooth'),
            subtitle: Text(bluetoothConnectPermission ? 'Conectado' : 'Disconectado'),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  foregroundColor: const Color.fromRGBO(0, 20, 137, 1)
              ),
              onPressed: () {
                FlutterBluetoothSerial.instance.openSettings();
              },
              child: const Text('Configurações'),
            ),
          ),
          const Divider(),
          const ListTile(title: Text('Acessos ao Dispositivo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
          SwitchListTile(
              title: const Text('Localização'),
              value: locationPermission,
              activeColor: Colors.white,
              activeTrackColor: const Color.fromRGBO(51, 177, 20, 1.0),
              onChanged: (bool value) async {
                if(!locationPermission) {
                  await Permission.location.request();
                  if(await Permission.location.isGranted) {
                    setState(() {
                      locationPermission = true;
                    });
                    return;
                  }
                  setState(() {
                    locationPermission = false;
                  });
                  return;
                }
                setState(() {
                  locationPermission = value;
                });
              }
          ),
          SwitchListTile(
              title: const Text('Detectar dispositivos por perto'),
              value: bluetoothScanPermission,
              activeColor: Colors.white,
              activeTrackColor: const Color.fromRGBO(51, 177, 20, 1.0),
              onChanged: (bool value) async {
                if(!bluetoothScanPermission) {
                  await Permission.bluetoothScan.request();
                  if(await Permission.bluetoothScan.isGranted) {
                    setState(() {
                      bluetoothScanPermission = true;
                    });
                    return;
                  }
                  setState(() {
                    bluetoothScanPermission = false;
                  });
                  return;
                } else {
                  setState(() {
                    bluetoothScanPermission = false;
                  });
                }
              }
          ),
          ListTile(
            title: const Text('Autorizações do Aplicativo'),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  foregroundColor: const Color.fromRGBO(0, 20, 137, 1)
              ),
              onPressed: () async {
                await openAppSettings();
              },
              child: const Text('Permissões'),
            ),
          ),
        ],
      ),
    );
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server);
        },
      ),
    );
  }
}
