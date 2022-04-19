import 'package:smspolitica/helper/sql_helper.dart';

class SMSHelper {
  static enviarMensaje(String destinatario, String mensaje) {
    //telephony.sendSms(to: destinatario, message: mensaje, statusListener: estadoMensaje);
    _agregarMensaje(mensaje, 0, destinatario, 1);
  }

  static Future<void> _agregarMensaje(
      String contenido, int idmensaje, String destinatario, int estado) async {
    await SQLHelper.createItem(contenido, idmensaje, destinatario, estado);
  }
}
