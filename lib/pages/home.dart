import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:smspolitica/helper/sms_helper.dart';
import 'package:smspolitica/helper/sql_helper.dart';
import 'package:telephony/telephony.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  List<String> destinatarios = message.data['telephone'].toString().split(",");
  for (var telefono in destinatarios) {
    SMSHelper.enviarMensaje(telefono, message.data['message']);
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final FirebaseMessaging _messaging;

  final telephony = Telephony.instance;

  void registerNotification() async {
    await Firebase.initializeApp();
    _messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );
    final token = await _messaging.getToken();
    debugPrint(token);
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        procesarMensaje(message);
      });
    } else {
      debugPrint('Debe dar permisos para acceder a mensajes sms');
    }
  }

  List<Mensaje> mensajes = [];

  void actualizarMensajes() async {
    final data = await SQLHelper.getItems();
    setState(() {
      mensajes = data;
    });
  }

  estadoMensaje(SendStatus status) {
    debugPrint(status.toString());
  }

  // For handling notification when the app is in terminated state
  checkForInitialMessage() async {
    await Firebase.initializeApp();
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      procesarMensaje(initialMessage);
    }
  }

  checkForSMSessage() async {
    final bool? result = await telephony.requestPhoneAndSmsPermissions;
    if (result != null && result) {}
    if (!mounted) return;
  }

  @override
  void initState() {
    registerNotification();
    checkForInitialMessage();
    checkForSMSessage();
    actualizarMensajes();
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      procesarMensaje(message);
    });
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) return;
    final isBackground = state == AppLifecycleState.paused;
    if (!isBackground) {
      actualizarMensajes();  
    }
  }

  procesarMensaje(RemoteMessage message) {
    List<String> destinatarios =
        message.data['telephone'].toString().split(",");
    for (var telefono in destinatarios) {
      SMSHelper.enviarMensaje(telefono, message.data['message']);
    }
    actualizarMensajes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      body: ListView.builder(
        itemCount: mensajes.length,
        itemBuilder: (BuildContext context, int index) {
          Mensaje item = mensajes.elementAt(index);
          return ListTile(
            leading: Icon(
              item.estado == 1 ? Icons.check : Icons.update,
              color: item.estado == 1 ? Colors.green : Colors.orange,
              size: 30,
            ),
            minLeadingWidth: 0,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.destinatario),
                Text(item.fecha),
              ],
            ),
            subtitle: Text(item.contenido),
          );
        },
      ),
    );
  }
}
