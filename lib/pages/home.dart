import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smspolitica/helper/sms_helper.dart';
import 'package:smspolitica/helper/sql_helper.dart';
import 'package:localstorage/localstorage.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  List<String> destinatarios = message.data['telephone'].toString().split(",");
  for (var telefono in destinatarios) {
    SMSHelper.enviarMensaje(telefono, message.data['message'], () {});
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final FirebaseMessaging _messaging;
  final LocalStorage storage = LocalStorage('token');
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
    storage.setItem('token', token);
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

  // For handling notification when the app is in terminated state
  checkForInitialMessage() async {
    await Firebase.initializeApp();
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      procesarMensaje(initialMessage);
    }
  }

  @override
  void initState() {
    registerNotification();
    checkForInitialMessage();
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

  refresh() {
    actualizarMensajes();
    setState(() {});
  }

  procesarMensaje(RemoteMessage message) {
    List<String> destinatarios =
        message.data['telephone'].toString().split(",");
    for (var telefono in destinatarios) {
      SMSHelper.enviarMensaje(telefono, message.data['message'], refresh);
    }
    actualizarMensajes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outlined),
            tooltip: 'Token',
            onPressed: () async {
              String token = storage.getItem("token").toString();
              await Clipboard.setData(ClipboardData(text: token));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  duration: Duration(milliseconds: 500),
                  content: Padding(
                    padding: EdgeInsets.symmetric(vertical: 25),
                    child: Text(
                      'Token copiado',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
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
