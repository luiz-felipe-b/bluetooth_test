import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothController extends GetxController {

  Future<List<BluetoothDevice>> scanDevices() async {
    List<BluetoothDevice> devices = [];

    if(await Permission.bluetoothScan.request().isGranted) {
      if(await Permission.bluetoothConnect.request().isGranted) {
        FlutterBluePlus.startScan(timeout: const Duration(seconds: 1000));

        FlutterBluePlus.scanResults.listen((results) {
          for (ScanResult result in results) {
            if (!devices.contains(result.device)) {
              devices.add(result.device);
            }
          }
        });

        // Wait for the scan to complete
        await Future.delayed(Duration(seconds: 4));

        FlutterBluePlus.stopScan();
      }
    }

    return devices;
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    // print(device);

    await device.connect(timeout: Duration(seconds: 15));

    device.connectionState.listen((isConnected) {
      print(isConnected);
      if(isConnected == BluetoothConnectionState.connected) {
        print("Device Connecting to ${device.name}");
      }
      else {
        print("Device disconnected");
      }
    });
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
}