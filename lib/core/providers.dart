import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final authProvider = Provider<AuthService>((ref) => AuthService.instance);