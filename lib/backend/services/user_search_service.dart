import '../models/app_user.dart';
import '../models/user_search_result.dart';

class UserSearchService {
  List<UserSearchResult> searchUsersByDisplayName({
    required List<AppUser> users,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return [];
    }

    return users
        .where((user) =>
            user.displayName.toLowerCase().contains(normalizedQuery))
        .map((user) => UserSearchResult(
              userId: user.uid,
              displayName: user.displayName,
            ))
        .toList();
  }
}