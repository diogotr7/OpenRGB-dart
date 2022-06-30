library openrgb;

import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:quiver/async.dart';

import 'header.dart';
import 'command.dart';

class OpenRGBClient {
  final Socket _socket;
  final StreamBuffer<int> _streamBuffer;

  OpenRGBClient(this._socket, this._streamBuffer);

  static Future<OpenRGBClient> connect(String host, int port) async {
    var socket= await Socket.connect(host, port);
    var streamBuffer = StreamBuffer<int>();
    
    socket.cast<List<int>>().pipe(streamBuffer);
    
    return OpenRGBClient(socket, streamBuffer);
  }

  Future send(int commandId, Uint8List data, {int deviceId = 0}) async {
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
  
  Future<Uint8List> readPacket() async
  {
    var headerBytes = Uint8List.fromList(await  _streamBuffer.read(16));

    var header = NetPacketHeader.parse(headerBytes);

    var packetBytes = Uint8List.fromList(await _streamBuffer.read(header.dataLength));

    return Future.value(packetBytes);
  }

  Future<int> getControllerCount() async {
    await send(CommandId.requestControllerCount, Uint8List(0));
    //wait for the result of onPacketReceived
    final payload = Uint8List(4);
    final ByteData payloadByteData = ByteData.sublistView(payload);
    return payloadByteData.getUint32(0, Endian.little);
  }
}
