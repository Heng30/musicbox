// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.33.

// ignore_for_file: invalid_use_of_internal_member, unused_import, unnecessary_import

import '../frb_generated.dart';
import 'data.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

// The type `CHANNEL` is not used by any `pub` functions, thus it is ignored.

Stream<MsgItem> msgCenterInit({dynamic hint}) =>
    RustLib.instance.api.msgCenterInit(hint: hint);

Future<void> send({required MsgItem item, dynamic hint}) =>
    RustLib.instance.api.send(item: item, hint: hint);
