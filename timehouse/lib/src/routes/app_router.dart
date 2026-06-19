import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/photo_detail_screen.dart';
import '../screens/families_screen.dart';
import '../screens/family_members_screen.dart';
import '../screens/my_space_screen.dart';
import '../screens/create_family_page.dart';
import '../screens/add_member_page.dart';
import '../services/storage_service.dart';

GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => FamiliesScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: '/my-space',
        builder: (context, state) => MySpaceScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => ProfileScreen(),
      ),
      GoRoute(
        path: '/families/:familyId/members',
        builder: (context, state) {
          final familyId = state.pathParameters['familyId']!;
          final familyName = state.extra as String? ?? '家庭组';
          return FamilyMembersScreen(familyId: familyId, familyName: familyName);
        },
      ),
      GoRoute(
        path: '/create-family',
        builder: (context, state) => const CreateFamilyPage(),
      ),
      GoRoute(
        path: '/add-member',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>;
          return AddMemberPage(
            familyId: extra['familyId']!,
            familyName: extra['familyName']!,
          );
        },
      ),
      GoRoute(
        path: '/photo/:id',
        builder: (context, state) {
          final photoId = state.pathParameters['id']!;
          String? familyId;
          List<String>? neighborIds;
          int? currentIndex;
          if (state.extra is Map<String, dynamic>) {
            final extra = state.extra as Map<String, dynamic>;
            familyId = extra['familyId'] as String?;
            final ids = extra['neighborIds'];
            if (ids is List) neighborIds = ids.cast<String>();
            final idx = extra['currentIndex'];
            if (idx is int) currentIndex = idx;
          }
          return PhotoDetailScreen(
            photoId: photoId,
            familyId: familyId,
            neighborIds: neighborIds,
            currentIndex: currentIndex,
          );
        },
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = StorageService.getUserId() != null;
      final isGoingToLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isGoingToLogin) {
        return '/login';
      }
      if (isLoggedIn && isGoingToLogin) {
        return '/';
      }
      return null;
    },
  );
}

late final GoRouter appRouter;

void initAppRouter() {
  appRouter = createAppRouter();
}
