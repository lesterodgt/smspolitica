import 'package:flutter/material.dart';
import 'package:smspolitica/helper/sql_helper.dart';
import 'package:telephony/telephony.dart';

const int smsingresado = 0;
const int smsentregado = 1;
const defaultColumns = [
  SmsColumn.ADDRESS,
  SmsColumn.BODY,
  SmsColumn.STATUS,
  SmsColumn.DATE_SENT,
  SmsColumn.ID
];

class SMSHelper {
  static enviarMensaje(
      String destinatario, String mensaje, Function() notifyParent) async {
    final telephony = Telephony.instance;
    int idMensajeBD =
        await _agregarMensaje(mensaje, 0, destinatario, smsingresado);
    await telephony.sendSms(
        to: destinatario,
        message: mensaje,
        statusListener: (SendStatus status) async {
          int estado = status == SendStatus.SENT ? smsingresado : smsentregado;
          if (estado == smsentregado) {
            List<SmsMessage> messages = await telephony.getSentSms(
                columns: defaultColumns,
                filter: SmsFilter.where(SmsColumn.ADDRESS)
                    .equals(destinatario)
                    .and(SmsColumn.BODY)
                    .equals(mensaje),
                sortOrder: [
                  OrderBy(SmsColumn.DATE_SENT, sort: Sort.DESC),
                ]);
            debugPrint(">>>--------${messages.length}-- mensaje enviado-<<<");
            if (messages.isNotEmpty) {
              SmsMessage item = messages.first;
              int idsms = item.id ?? 0;
              SQLHelper.updateItem(idMensajeBD, estado, idsms);
              notifyParent();
            }
          }
        });
  }

  static Future<int> _agregarMensaje(
      String contenido, int idmensaje, String destinatario, int estado) async {
    int id =
        await SQLHelper.createItem(contenido, idmensaje, destinatario, estado);
    return id;
  }

  static estadoMensaje(SendStatus status) {
    debugPrint(status.toString());
  }
}
