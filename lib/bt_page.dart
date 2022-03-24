import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'safebutton.dart';

FlutterBluePlus fbp = FlutterBluePlus.instance;

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({Key? key}) : super(key: key);

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  bool permissionsGranted = false;
  bool isScanning = false;

  List<BluetoothDevice> devices = [];
  List<BluetoothDevice> alreadyConnectedDevices = [];

  @override
  void initState() {
    super.initState();
    ensurePermissionsGranted()
        .then((result) => setState(() => permissionsGranted = result));
  }

  Future<bool> ensurePermissionsGranted() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetooth, // relevant only pre Android 12
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    print('statuses: $statuses');

    // for readability
    bool loc =
        statuses[Permission.locationWhenInUse] == PermissionStatus.granted;
    bool bt = statuses[Permission.bluetooth] == PermissionStatus.granted;
    bool bt31Plus =
        statuses[Permission.bluetoothScan] == PermissionStatus.granted &&
            statuses[Permission.bluetoothConnect] == PermissionStatus.granted;
    return loc && (bt || bt31Plus);
  }

  Future<void> scanForDevices() async {
    // clear devices list
    setState(() {
      isScanning = true;
      devices.clear();
      alreadyConnectedDevices.clear();
    });

    // start a scan and add found devices to devices list.
    fbp.scan(timeout: const Duration(seconds: 3)).listen(
          (scanres) => setState(() => devices.add(scanres.device)),
        );

    // find already connected devices (won't appear in first scan) and add.
    fbp.connectedDevices.then((res) {
      setState(() => devices.addAll(res));
      alreadyConnectedDevices = res;
      print('already connected: $alreadyConnectedDevices');
    });

    Future.delayed(const Duration(seconds: 3))
        .then((_) => setState(() => isScanning = false));
  }

  void Function() toggleConnect(BluetoothDevice d) => () {
        if (alreadyConnectedDevices.contains(d)) {
          // disconnect and then refresh the list
          d.disconnect().then((_) => scanForDevices());
        } else {
          // connect and then refresh the list
          d.connect(autoConnect: false).then((_) => scanForDevices());
        }
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
      ),
      body: permissionsGranted
          ? Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Text('scan for devices and tap to toggle connect.'),
                ),
                Expanded(child: devicesList()),
                SafeButton(
                  text: 'scan for devices',
                  onPressed: scanForDevices,
                  blockInput: isScanning,
                ),
              ],
            )
          : const Text('permissions not granted'),
    );
  }

  ListView devicesList() => ListView(
        children: devices.map(
          (d) {
            String name = d.name.isEmpty ? 'unnamed' : d.name;
            if (alreadyConnectedDevices.contains(d)) name += ' - connected';

            return GestureDetector(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(name),
                ),
              ),
              onTap: (isScanning) ? null : toggleConnect(d),
            );
          },
        ).toList(),
      );

  @override
  void dispose() {
    for (final d in alreadyConnectedDevices) {
      try {
        d.disconnect();
      } catch (e) {
        print(e);
        continue;
      }
    }
    super.dispose();
  }
}
