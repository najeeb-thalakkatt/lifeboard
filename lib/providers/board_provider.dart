import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lifeboard/models/board_model.dart';
import 'package:lifeboard/providers/space_provider.dart';

/// Streams all boards for a space.
final boardsProvider =
    StreamProvider.family<List<BoardModel>, String>((ref, spaceId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getBoards(spaceId);
});

/// Currently selected board ID within the board view.
final selectedBoardIdProvider = StateProvider<String?>((ref) => null);

/// Gets or creates the default board for a space.
final defaultBoardProvider =
    FutureProvider.family<BoardModel, String>((ref, spaceId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = FirebaseAuth.instance.currentUser;
  return firestoreService.getDefaultBoard(
    spaceId: spaceId,
    userId: user?.uid ?? '',
  );
});
