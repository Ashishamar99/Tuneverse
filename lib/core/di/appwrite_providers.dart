import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _endpoint = 'https://sgp.cloud.appwrite.io/v1';
const _projectId = '6a7778a300154a04c1c6';
const appwriteDatabaseId = 'tuneverse';
const backupsCollectionId = 'backups';

final appwriteClientProvider = Provider<Client>((ref) {
  return Client()
      .setEndpoint(_endpoint)
      .setProject(_projectId)
      .setSelfSigned(status: false);
});

final appwriteAccountProvider = Provider<Account>((ref) {
  return Account(ref.watch(appwriteClientProvider));
});

final appwriteDatabasesProvider = Provider<Databases>((ref) {
  return Databases(ref.watch(appwriteClientProvider));
});

final appwriteRealtimeProvider = Provider<Realtime>((ref) {
  return Realtime(ref.watch(appwriteClientProvider));
});

final appwriteUserProvider = FutureProvider<models.User?>((ref) async {
  final account = ref.watch(appwriteAccountProvider);
  try {
    return await account.get();
  } catch (_) {
    return null;
  }
});
