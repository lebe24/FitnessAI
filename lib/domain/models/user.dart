class UserEntity {
  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl;

  UserEntity({this.avatarUrl, required this.id, this.email, this.name});
}
