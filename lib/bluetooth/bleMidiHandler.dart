// (c) 2020-2021 Dian Iliev (Tuntorius)
// This code is licensed under MIT license (see LICENSE.md for details)

//Good explanation for location usage
//https://support.chefsteps.com/hc/en-us/articles/360009480814-I-have-an-Android-Why-am-I-being-asked-to-allow-location-access-
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mighty_plug_manager/bluetooth/ble_controllers/WinBleController.dart';
import 'ble_controllers/DummyBLEController.dart';
import 'ble_controllers/FlutterBluePlusController.dart';
import 'package:permission_handler/permission_handler.dart';
import '../platform/platformUtils.dart';
import 'ble_controllers/BLEController.dart';
import 'ble_controllers/WebBleController.dart';

typedef BluetoothErrorCallback = void Function(BleError, dynamic data);

class BLEMidiHandler {
  //List of devices that doesn't advertise their midi service
  static const List<String> forcedDevices = [
    "FootCtrl" //Cuvave / M-Wave Chocolate
  ];

  static final BLEMidiHandler _bleHandler = BLEMidiHandler._();

  late BLEController bleController;

  Stream<MidiSetupStatus> get status => bleController.status;
  Stream<bool> get isScanningStream => bleController.isScanningStream;
  MidiSetupStatus get currentStatus => bleController.currentStatus;

  bool _manualScan = false;
  bool _granted = false;
  bool _permanentlyDenied = false;

  bool get permissionGranted => PlatformUtils.isWeb || _granted;
  bool get permanentlyDenied => !PlatformUtils.isWeb && _permanentlyDenied;

  BleState get bleState => bleController.bleState;
  bool get isScanning => bleController.isScanning;
  bool get manualScan => _manualScan;

  factory BLEMidiHandler.instance() {
    return _bleHandler;
  }

  var _nuxDevices = <BLEScanResult>[];

  List<BLEScanResult> get nuxDevices => _nuxDevices;

  //controller devices
  var _controllerDevices = <BLEScanResult>[];

  List<BLEScanResult> get controllerDevices => _controllerDevices;

  BLEDevice? get connectedDevice {
    return bleController.connectedDevice;
  }

  BLEMidiHandler._() {
    if (PlatformUtils.isMobile) {
      bleController = FlutterBluePlusController(forcedDevices);
    } else if (PlatformUtils.isWeb) {
      bleController = WebBleController(forcedDevices);
    } else if (PlatformUtils.isWindows) {
      bleController = WinBleController(forcedDevices);
    } else {
      bleController = DummyBLEController(forcedDevices);
    }
  }

  initBle(BluetoothErrorCallback onError) async {
    if (PlatformUtils.isMobile) {
      PermissionStatus pStatus;
      bool askOneTime = false;
      do {
        pStatus = await Permission.location.status;
        if (pStatus.isGranted) break;
        if (!askOneTime) {
          pStatus = await Permission.location.request();
          if (pStatus.isPermanentlyDenied) _permanentlyDenied = true;
          askOneTime = true;
          if (!pStatus.isGranted) {
            onError(BleError.permissionDenied, pStatus);
          }
        }
        Future.delayed(const Duration(milliseconds: 500));
      } while (!pStatus.isGranted);
    }
    debugPrint("Location permission granted!");
    _granted = true;
    _permanentlyDenied = false;

    var available = await bleController.isAvailable();
    if (!available) {
      onError(BleError.unavailable, null);
    }

    if (PlatformUtils.isMobile) {
      ServiceStatus ss = await Permission.location.serviceStatus;

      if (!ss.isEnabled) {
        onError(BleError.locationServiceOff, null);
      }
    }
    debugPrint("BLEMidiHandler:Init()");

    bleController.init(_onScanResults);
  }

  void _onScanResults(
      List<BLEScanResult> nuxResults, List<BLEScanResult> controllerResults) {
    _nuxDevices = nuxResults;
    _controllerDevices = controllerResults;
  }

  void setAmpDeviceIdProvider(List<String> Function() provider) {
    bleController.setAmpDeviceIdProvider(provider);
  }

  void startScanning(bool manual) {
    if (!_granted) return;
    _manualScan = manual;
    bleController.startScanning();
  }

  void stopScanning() {
    if (!_granted) return;
    bleController.stopScanning();
  }

  Future<BLEConnection?> connectToDevice(BLEDevice device) async {
    if (!_granted) return null;
    return bleController.connectToDevice(device);
  }

  void disconnectDevice() async {
    if (!_granted) return;
    bleController.disconnectDevice();
  }

  StreamSubscription<List<int>> registerDataListener(
      Function(List<int>) listener) {
    return bleController.registerDataListener(listener);
  }

  void sendData(List<int> data) {
    if (!_granted) return;
    bleController.sendData(data);
  }

  void dispose() {
    bleController.dispose();
  }
}
