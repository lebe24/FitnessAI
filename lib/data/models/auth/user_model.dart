import 'package:fitness/domain/models/user.dart';

class UserModel extends UserEntity {
  UserModel({
    required String id,
    String? email,
    String? name,
    String? avatarUrl,
  }) : super(id: id, email: email, name: name, avatarUrl: avatarUrl);

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final userMetadata = map['user_metadata'] as Map<String, dynamic>?;
    final avatarUrl = userMetadata?['avatar_url'] as String? ??
        userMetadata?['picture'] as String?;

    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String?,
      name: userMetadata?['full_name'] as String? ??
          userMetadata?['name'] as String?,
      avatarUrl: avatarUrl,
    );
  }
}
