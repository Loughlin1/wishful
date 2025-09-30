import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_profile_api_service.dart';
import '../widgets/wishful_app_bar.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  static const Map<String, String> _interestEmojis = {
    'Sports': '🏀',
    'Music': '🎵',
    'Books': '📚',
    'Tech': '💻',
    'Fashion': '👗',
    'Food': '🍔',
    'Travel': '✈️',
    'Art': '🎨',
    'Fitness': '🏋️',
    'Gaming': '🎮',
    'Gardening': '🪴',
    'Movies': '🎬',
    'DIY': '🛠️',
    'Outdoors': '🌲',
    'Pets': '🐶',
    'Photography': '📷',
  };
  static const List<String> _allInterests = [
    'Sports', 'Music', 'Books', 'Tech', 'Fashion', 'Food', 'Travel', 'Art',
    'Fitness', 'Gaming', 'Gardening', 'Movies', 'DIY', 'Outdoors', 'Pets', 'Photography',
  ];
  List<String> _selectedInterests = [];
  final _formKey = GlobalKey<FormState>();
  final _firstnameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
    String? _selectedGender;
  final _tshirtController = TextEditingController();
  final _shoeController = TextEditingController();
  final _pantsJeansController = TextEditingController();
  final _dressController = TextEditingController();
  final _shirtController = TextEditingController();
  final _jacketController = TextEditingController();
  final _hatController = TextEditingController();
  final _gloveController = TextEditingController();
  final _beltController = TextEditingController();
  final _braController = TextEditingController();
  final _ringController = TextEditingController();
  final _sockController = TextEditingController();
  final _heightController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  final _apiService = UserProfileApiService(baseUrl: 'http://localhost:8000'); // Update baseUrl as needed
  bool _loading = true;
  String _shoeSizeType = 'UK';

  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await _getCurrentUser();
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final profile = await _apiService.fetchProfile(user.uid);
    if (profile != null) {
      _profile = profile;
  _firstnameController.text = profile.firstName ?? '';
  _lastnameController.text = profile.lastName ?? '';
  _emailController.text = profile.email ?? '';
      _selectedGender = profile.gender;
      _tshirtController.text = profile.tshirtSize ?? '';
      // Try to parse shoe size type from saved value, fallback to UK
      final shoe = profile.shoeSize ?? '';
      final RegExpMatch? match = RegExp(r'^(UK|US|EU):\s*(.*)').firstMatch(shoe);
      if (match != null) {
        _shoeSizeType = match.group(1)!;
        _shoeController.text = match.group(2) ?? '';
      } else {
        _shoeSizeType = 'UK';
        _shoeController.text = shoe;
      }
      _pantsJeansController.text = profile.pantsJeansSize ?? '';
      _dressController.text = profile.dressSize ?? '';
      _shirtController.text = profile.shirtSize ?? '';
      _jacketController.text = profile.jacketSize ?? '';
      _hatController.text = profile.hatSize ?? '';
      _gloveController.text = profile.gloveSize ?? '';
      _beltController.text = profile.beltSize ?? '';
      _braController.text = profile.braSize ?? '';
      _ringController.text = profile.ringSize ?? '';
      _sockController.text = profile.sockSize ?? '';
      _heightController.text = profile.height ?? '';
      _notesController.text = profile.notes ?? '';
      _selectedInterests = List<String>.from(profile.interests ?? []);
      if (profile.dateOfBirth != null && profile.dateOfBirth!.isNotEmpty) {
        _selectedDateOfBirth = DateTime.tryParse(profile.dateOfBirth!);
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = await _getCurrentUser();
      if (user == null) return;
        final profile = UserProfile(
          firstName: _firstnameController.text,
          lastName: _lastnameController.text,
          email: _emailController.text,
          gender: _selectedGender,
          tshirtSize: _tshirtController.text,
          shoeSize: '${_shoeSizeType}: ${_shoeController.text}',
          pantsJeansSize: _pantsJeansController.text,
          dressSize: _dressController.text,
          shirtSize: _shirtController.text,
          jacketSize: _jacketController.text,
          hatSize: _hatController.text,
          gloveSize: _gloveController.text,
          beltSize: _beltController.text,
          braSize: _braController.text,
          ringSize: _ringController.text,
          sockSize: _sockController.text,
          height: _heightController.text,
          notes: _notesController.text,
          interests: _selectedInterests,
          dateOfBirth: _selectedDateOfBirth != null ? _selectedDateOfBirth!.toIso8601String().substring(0, 10) : null,
        );
      // Try update, if not found, create
      try {
        await _apiService.updateProfile(profile, user.uid);
      } catch (e) {
        await _apiService.createProfile(profile, user.uid);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!')),
      );
    }
  }
  Future<dynamic> _getCurrentUser() async {
    // Import FirebaseAuth at the top if not already
    // import 'package:firebase_auth/firebase_auth.dart';
    return Future.value(FirebaseAuth.instance.currentUser);
  }

  @override
  void dispose() {
  _firstnameController.dispose();
  _lastnameController.dispose();
  _emailController.dispose();
    // No controller for gender
    _tshirtController.dispose();
    _shoeController.dispose();
    _pantsJeansController.dispose();
    _dressController.dispose();
    _shirtController.dispose();
    _jacketController.dispose();
    _hatController.dispose();
    _gloveController.dispose();
    _beltController.dispose();
    _braController.dispose();
    _ringController.dispose();
    _sockController.dispose();
    _heightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
      return Scaffold(
        appBar: const WishfulAppBar(),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  width: 600,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        // --- Personal Information ---
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text('Personal Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                        TextFormField(
                          controller: _firstnameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            hintText: 'Enter your first name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastnameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            hintText: 'Enter your last name',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                          ),
                        ),
                         const SizedBox(height: 16),
                         DropdownButtonFormField<String>(
                           value: _selectedGender,
                           decoration: const InputDecoration(
                             labelText: 'Gender',
                             border: OutlineInputBorder(),
                           ),
                           items: const [
                             DropdownMenuItem(value: 'Male', child: Text('Male')),
                             DropdownMenuItem(value: 'Female', child: Text('Female')),
                             DropdownMenuItem(value: 'Other', child: Text('Other')),
                             DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                           ],
                           onChanged: (val) {
                             setState(() {
                               _selectedGender = val;
                             });
                           },
                         ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Date of Birth:', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDateOfBirth ?? DateTime(2000, 1, 1),
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _selectedDateOfBirth = picked;
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date of Birth',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(
                                    _selectedDateOfBirth != null
                                        ? '${_selectedDateOfBirth!.year}-${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}'
                                        : 'Select date',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      // --- Interests ---
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text('Interests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _allInterests.map((interest) {
                          final selected = _selectedInterests.contains(interest);
                          final emoji = _interestEmojis[interest] ?? '';
                          return FilterChip(
                            label: Text('$emoji $interest'),
                            selected: selected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedInterests.add(interest);
                                } else {
                                  _selectedInterests.remove(interest);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Clothing Sizes Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Text('Clothing Sizes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                                TextFormField(
                                  controller: _tshirtController,
                                  decoration: const InputDecoration(
                                    labelText: 'T-shirt Size',
                                    hintText: 'e.g. M, L, XL',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _shirtController,
                                  decoration: const InputDecoration(
                                    labelText: 'Shirt Size',
                                    hintText: 'e.g. M, L, XL, 15.5/34',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _jacketController,
                                  decoration: const InputDecoration(
                                    labelText: 'Jacket/Coat Size',
                                    hintText: 'e.g. L, XL, 42',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _dressController,
                                  decoration: const InputDecoration(
                                    labelText: 'Dress Size',
                                    hintText: 'e.g. US 8, UK 10, EU 38',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _pantsJeansController,
                                  decoration: const InputDecoration(
                                    labelText: 'Pants/Jeans Size',
                                    hintText: 'e.g. 32x32, EU 40',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _heightController,
                                  decoration: const InputDecoration(
                                    labelText: 'Height',
                                    hintText: 'e.g. 5\'10\", 178 cm',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Accessories Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 8.0),
                                  child: Text('Accessories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                                TextFormField(
                                  controller: _hatController,
                                  decoration: const InputDecoration(
                                    labelText: 'Hat Size',
                                    hintText: 'e.g. M, 7 1/4',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _gloveController,
                                  decoration: const InputDecoration(
                                    labelText: 'Glove Size',
                                    hintText: 'e.g. M, 8.5',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _beltController,
                                  decoration: const InputDecoration(
                                    labelText: 'Belt Size',
                                    hintText: 'e.g. 34 in, 90 cm',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _braController,
                                  decoration: const InputDecoration(
                                    labelText: 'Bra Size',
                                    hintText: 'e.g. 34B',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _ringController,
                                  decoration: const InputDecoration(
                                    labelText: 'Ring Size',
                                    hintText: 'e.g. 6, 7, 8',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _sockController,
                                  decoration: const InputDecoration(
                                    labelText: 'Sock Size',
                                    hintText: 'e.g. 9-11, M',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // --- Shoe Size ---
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text('Shoe Size', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                      TextFormField(
                        controller: _shoeController,
                        decoration: InputDecoration(
                          labelText: 'Shoe Size',
                          hintText: 'e.g. 9, 42, 10.5',
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 8, right: 8),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _shoeSizeType,
                                items: const [
                                  DropdownMenuItem(value: 'UK', child: Text('UK')),
                                  DropdownMenuItem(value: 'US', child: Text('US')),
                                  DropdownMenuItem(value: 'EU', child: Text('EU')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _shoeSizeType = val);
                                },
                              ),
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 24),

                      // --- Other ---
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 0.0),
                          child: Text('Other', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Other Notes',
                          hintText: 'e.g. favorite color, allergies',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
