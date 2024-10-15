import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:teste_bluetooth_pi/models/enum/deviceavailability.dart';

class DeviceWithAvailability {
  BluetoothDevice device;
  DeviceAvailability availability;
  int? rssi;

  DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}