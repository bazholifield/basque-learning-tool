import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Set at build time: flutter build apk --dart-define=API_BASE=http://10.0.0.29:8000
// The default works on desktop, and on the phone through adb reverse (the Helm sets that up).
const String kBaseUrl = String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:8000');

final apiClientProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: kBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));
});
