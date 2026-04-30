import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Change this to your laptop's local IP when testing on a physical device.
const String kBaseUrl = 'http://localhost:8000';

final apiClientProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: kBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));
});
