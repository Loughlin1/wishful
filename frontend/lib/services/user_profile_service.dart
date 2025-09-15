import 'package:hive/hive.dart';
import '../models/user_profile.dart';

class UserProfileService {
  static const String _boxName = 'userProfileBox';

  Future<void> saveProfile(UserProfile profile) async {
    var box = await Hive.openBox(_boxName);
    await box.put('profile', profile.toMap());
  }

  Future<UserProfile?> loadProfile() async {
    var box = await Hive.openBox(_boxName);
    final map = box.get('profile');
    if (map != null) {
      return UserProfile.fromMap(Map<String, dynamic>.from(map));
    }
    return null;
  }
}
