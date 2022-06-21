library openrgb;

import 'dart:io';
import 'dart:typed_data';

import 'header.dart';
import 'command.dart';

class OpenRGBClient {
  final Socket _socket;

  OpenRGBClient(this._socket);

  static Future<OpenRGBClient> connect(String host, int port) async {
    final socket = await Socket.connect(host, port);
    socket.listen((data) async {
      //check if we have at least the header.
      if (data.length < NetPacketHeader.headerLength) {
        throw Exception('Incomplete packet');
      }
      final headerBytes = data.sublist(0, NetPacketHeader.headerLength);
      final header = NetPacketHeader.parse(headerBytes);
      if (data.length < header.dataLength + NetPacketHeader.headerLength) {
        throw Exception('Incomplete packet');
      }
      //we have the whole packet.
      final payload = data.sublist(
          NetPacketHeader.headerLength, header.dataLength + NetPacketHeader.headerLength);

      onPacketReceived(header, payload);
    });

    return OpenRGBClient(socket);
  }

  Future<void> send(int commandId, Uint8List data, {int deviceId = 0}) async {
    final header = NetPacketHeader(
      deviceIndex: deviceId,
      commandId: commandId,
      dataLength: data.length,
    );
    final headerData = header.toBytes();
    final packet = Uint8List(headerData.length + data.length);
    _socket.add(packet);
    await _socket.flush();
  }
  
  static void onPacketReceived(NetPacketHeader header , Uint8List payload) 
  {
    //store the payload somewhere, idk?
  }

  Future<int> getControllerCount() async {
    await send(CommandId.requestControllerCount, Uint8List(0));
    //wait for the result of onPacketReceived
    final payload = new Uint8List(4);
    final ByteData payloadByteData = ByteData.sublistView(payload);
    return payloadByteData.getUint32(0, Endian.little);
  }
}
