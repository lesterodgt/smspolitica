import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE mensaje(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        contenido TEXT,
        idmensaje int,
        destinatario TEXT,
        fecha TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        estado int
      )
      """);
  }
  // id: the id of the message
  // contenido: mensaje
  // idmensaje
  // destinatario
  // fecha: fecha registro
  // estado:

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'mensajes.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  static Future<int> createItem(
      String contenido, int idmensaje, String destinatario, int estado) async {
    final db = await SQLHelper.db();

    final data = {
      'contenido': contenido,
      'idmensaje': idmensaje,
      'destinatario': destinatario,
      'estado': estado
    };
    final id = await db.insert('mensaje', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Mensaje>> getItems() async {
    final db = await SQLHelper.db();
    List<Mensaje> mensajes = [];
    var mensajesDB = await db.query('mensaje', orderBy: "id desc");
    for (var itemDB in mensajesDB) {
      mensajes.add(Mensaje.fromMap(itemDB));
    }
    return mensajes;
  }

  static Future<List<Mensaje>> obtenerNoEnviados() async {
    final db = await SQLHelper.db();
    List<Mensaje> mensajes = [];
    var mensajesDB =
        await db.rawQuery('SELECT * FROM mensaje where estado = 0;');
    for (var itemDB in mensajesDB) {
      mensajes.add(Mensaje.fromMap(itemDB));
    }
    return mensajes;
  }

  // Read a single item by id
  // The app doesn't use this method but I put here in case you want to see it
  static Future<List<Map<String, dynamic>>> getItem(int id) async {
    final db = await SQLHelper.db();
    return db.query('mensaje', where: "id = ?", whereArgs: [id], limit: 1);
  }

  //
  static Future<int> updateItem(int id, int estado, int idsms) async {
    final db = await SQLHelper.db();

    final data = {'idmensaje': idsms, 'estado': estado};
    final result =
        await db.update('mensaje', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  // Delete
  static Future<void> deleteItem(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("mensaje", where: "id = ?", whereArgs: [id]);
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }
}

class Mensaje {
  late int id;
  late String contenido;
  late int idmensaje;
  late String destinatario;
  late String fecha;
  late int estado;

  Mensaje(this.id, this.contenido, this.idmensaje, this.destinatario,
      this.fecha, this.estado);
  Mensaje.fromMap(Map map) {
    id = map['id'];
    contenido = map['contenido'];
    idmensaje = map['idmensaje'];
    destinatario = map['destinatario'];
    fecha = map['fecha'];
    estado = map['estado'];
  }
}
