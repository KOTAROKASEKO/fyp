import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 1)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String displayName;

  @HiveField(2)
  final String username;

  @HiveField(3)
  final String bio;

  @HiveField(4)
  final String profileImageUrl;

  @HiveField(5)
  int postCount;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.username,
    required this.bio,
    required this.profileImageUrl,
    required this.postCount,
  });

  // Factory for creating an empty/default profile for initial loading states
  factory UserProfile.empty() {
    return UserProfile(
      uid: '',
      displayName: 'User',
      username: 'username',
      bio: '',
      profileImageUrl: '',
      postCount: 0,
    );
  }
}