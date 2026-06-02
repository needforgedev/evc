import 'package:flutter_test/flutter_test.dart';
import 'package:evc_realtime/evc_realtime.dart';

void main() {
  test('realtime package exposes its transport', () {
    expect(evcRealtimeTransport, 'supabase_realtime');
  });
}