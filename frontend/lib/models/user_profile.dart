class UserProfile {
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

  UserProfile({
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
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
    };
  }
}
