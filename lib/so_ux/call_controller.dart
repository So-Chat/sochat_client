import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sochat_client/modules/calls/call_service.dart';

final callControllerProvicer = FutureProvider<CallController>((ref) async {
  return CallController(await ref.watch(callServiceProvider.future));
});

class CallController {
  final CallService _callService;

  CallController(this._callService);
}