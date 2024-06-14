// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

class BluetoothDevice {
  final String name;
  final String address;
  final bool paired;
  final bool nearby;

  const BluetoothDevice(this.name, this.address,
      {this.nearby = false, this.paired = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothDevice &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          address == other.address;

  @override
  int get hashCode => name.hashCode ^ address.hashCode;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'address': address,
      'paired': paired,
      'nearby': nearby,
    };
  }

  @override
  String toString() {
    return 'BluetoothDevice{name: $name, address: $address, paired: $paired, nearby: $nearby}';
  }

  factory BluetoothDevice.fromMap(Map<String, dynamic> map) {
    return BluetoothDevice(
      map['name'] as String,
      map['address'] as String,
      paired: map['paired'] as bool,
      nearby: map['nearby'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory BluetoothDevice.fromJson(String source) =>
      BluetoothDevice.fromMap(json.decode(source) as Map<String, dynamic>);
}

class FlutterScanBluetooth {
  static final _singleton = FlutterScanBluetooth._();
  final MethodChannel _channel = const MethodChannel('flutter_scan_bluetooth');
  final List<BluetoothDevice> _pairedDevices = [];
  final StreamController<BluetoothDevice> _controller =
      StreamController.broadcast();
  final StreamController<bool> _scanStopped = StreamController.broadcast();

  factory FlutterScanBluetooth() => _singleton;

  FlutterScanBluetooth._() {
    _channel.setMethodCallHandler((methodCall) async {
      switch (methodCall.method) {
        case 'action_new_device':
          _newDevice(methodCall.arguments);
          break;
        case 'action_scan_stopped':
          _scanStopped.add(true);
          break;
      }
      return null;
    });
  }

  Stream<BluetoothDevice> get devices => _controller.stream;

  Stream<bool> get scanStopped => _scanStopped.stream;

  Future<void> requestPermissions() async {
    await _channel.invokeMethod('action_request_permissions');
  }

  Future<void> startScan({pairedDevices = false}) async {
    final bondedDevices =
        await _channel.invokeMethod('action_start_scan', pairedDevices);
    for (var device in bondedDevices) {
      final d =
          BluetoothDevice(device['name'], device['address'], paired: true);
      _pairedDevices.add(d);
      _controller.add(d);
    }
  }

  Future<void> close() async {
    await _scanStopped.close();
    await _controller.close();
  }

  Future<void> stopScan() => _channel.invokeMethod('action_stop_scan');

  void _newDevice(device) {
    _controller.add(BluetoothDevice(
      device['name'],
      device['address'],
      nearby: true,
      paired: _pairedDevices
              .firstWhereOrNull((item) => item.address == device['address']) !=
          null,
    ));
  }
}
