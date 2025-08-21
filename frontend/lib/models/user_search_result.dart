class UserSearchResult {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;

  UserSearchResult({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) => UserSearchResult(
        uid: json['uid'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        email: json['email'],
      );
}
