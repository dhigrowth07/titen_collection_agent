import 'package:flutter/material.dart';
import 'package:collection_agent/app/app.dart';
import 'package:collection_agent/app/routes/app_routes.dart';
import 'package:collection_agent/core/network/api_client.dart';
import 'package:collection_agent/core/storage/secure_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore authenticated session from SecureStorage
  final token = await SecureStorage.instance.read(ApiClient.keyToken);
  final profile = await SecureStorage.instance.read(ApiClient.keyCollectorProfile);
  final tenantId = await SecureStorage.instance.read(ApiClient.keyTenantId);

  final bool isLoggedIn = token != null && token.isNotEmpty && profile != null && profile.isNotEmpty;
  if (isLoggedIn && tenantId != null && tenantId.isNotEmpty) {
    ApiClient.instance.setTenantId(tenantId);
  }

  runApp(NestPilotApp(
    initialRoute: isLoggedIn ? AppRoutes.roomManagement : AppRoutes.login,
  ));
}
