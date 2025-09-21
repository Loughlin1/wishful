class UserProfile {
  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? gender,
    String? tshirtSize,
    String? shoeSize,
    String? pantsJeansSize,
    String? dressSize,
    String? shirtSize,
    String? jacketSize,
    String? hatSize,
    String? gloveSize,
    String? beltSize,
    String? braSize,
    String? ringSize,
    String? sockSize,
    String? height,
    String? notes,
    List<String>? interests,
    String? dateOfBirth,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      tshirtSize: tshirtSize ?? this.tshirtSize,
      shoeSize: shoeSize ?? this.shoeSize,
      pantsJeansSize: pantsJeansSize ?? this.pantsJeansSize,
      dressSize: dressSize ?? this.dressSize,
      shirtSize: shirtSize ?? this.shirtSize,
      jacketSize: jacketSize ?? this.jacketSize,
      hatSize: hatSize ?? this.hatSize,
      gloveSize: gloveSize ?? this.gloveSize,
      beltSize: beltSize ?? this.beltSize,
      braSize: braSize ?? this.braSize,
      ringSize: ringSize ?? this.ringSize,
      sockSize: sockSize ?? this.sockSize,
      height: height ?? this.height,
      notes: notes ?? this.notes,
      interests: interests ?? this.interests,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }
  String? firstName;
  String? lastName;
  String? email;
  String? gender;
  String? tshirtSize;
  String? shoeSize;
  String? pantsJeansSize;
  String? dressSize;
  String? shirtSize;
  String? jacketSize;
  String? hatSize;
  String? gloveSize;
  String? beltSize;
  String? braSize;
  String? ringSize;
  String? sockSize;
  String? height;
  String? notes;
  List<String>? interests;
  String? dateOfBirth;

  UserProfile({
    this.firstName,
    this.lastName,
    this.email,
    this.gender,
    this.tshirtSize,
    this.shoeSize,
    this.pantsJeansSize,
    this.dressSize,
    this.shirtSize,
    this.jacketSize,
    this.hatSize,
    this.gloveSize,
    this.beltSize,
    this.braSize,
    this.ringSize,
    this.sockSize,
    this.height,
    this.notes,
    this.interests,
    this.dateOfBirth,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      firstName: map['first_name'] as String? ?? map['firstName'] as String?,
      lastName: map['last_name'] as String? ?? map['lastName'] as String?,
      email: map['email'] as String?,
      gender: map['gender'] as String?,
      tshirtSize: map['tshirtSize'] as String?,
      shoeSize: map['shoeSize'] as String?,
      pantsJeansSize: map['pantsJeansSize'] as String?,
      dressSize: map['dressSize'] as String?,
      shirtSize: map['shirtSize'] as String?,
      jacketSize: map['jacketSize'] as String?,
      hatSize: map['hatSize'] as String?,
      gloveSize: map['gloveSize'] as String?,
      beltSize: map['beltSize'] as String?,
      braSize: map['braSize'] as String?,
      ringSize: map['ringSize'] as String?,
      sockSize: map['sockSize'] as String?,
      height: map['height'] as String?,
      notes: map['notes'] as String?,
      interests: map['interests'] != null ? List<String>.from(map['interests']) : null,
      dateOfBirth: map['dateOfBirth'] as String? ?? map['date_of_birth'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'gender': gender,
      'tshirtSize': tshirtSize,
      'shoeSize': shoeSize,
      'pantsJeansSize': pantsJeansSize,
      'dressSize': dressSize,
      'shirtSize': shirtSize,
      'jacketSize': jacketSize,
      'hatSize': hatSize,
      'gloveSize': gloveSize,
      'beltSize': beltSize,
      'braSize': braSize,
      'ringSize': ringSize,
      'sockSize': sockSize,
      'height': height,
      'notes': notes,
      'interests': interests,
      'dateOfBirth': dateOfBirth,
    };
  }
}
