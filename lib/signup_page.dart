// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'package:flutter/services.dart';
import 'package:showcaseview/showcaseview.dart';
import 'Shared/signup_help_showcase.dart';
import '../PendingPatientPage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  SignUpPageState createState() => SignUpPageState();
}

class SignUpPageState extends State<SignUpPage> {
  final GlobalKey _emailShowcaseKey = GlobalKey();
  final GlobalKey _passwordShowcaseKey = GlobalKey();
  final GlobalKey _imageShowcaseKey = GlobalKey();
  final GlobalKey _firstNameShowcaseKey = GlobalKey();
  final GlobalKey _fatherNameShowcaseKey = GlobalKey();
  final GlobalKey _grandfatherNameShowcaseKey = GlobalKey();
  final GlobalKey _familyNameShowcaseKey = GlobalKey();
  final GlobalKey _idNumberShowcaseKey = GlobalKey();
  final GlobalKey _birthDateShowcaseKey = GlobalKey();
  final GlobalKey _genderShowcaseKey = GlobalKey();
  final GlobalKey _phoneShowcaseKey = GlobalKey();
  final GlobalKey _addressShowcaseKey = GlobalKey();
  final GlobalKey _confirmPasswordShowcaseKey = GlobalKey();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _grandfatherNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _birthDate;
  String? _gender;
  dynamic _patientImage;
  dynamic _idImage;
  bool _isLoading = false;
  bool _userIsTypingOrFocused = false;

  final Color primaryColor = const Color(0xFF2A7A94);
  Future<void> _pickIdImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (!mounted) return;
          setState(() => _idImage = bytes);
        } else {
          if (!mounted) return;
          setState(() => _idImage = File(image.path));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_translate('image_error')}: $e')),
      );
    }
  }

  Future<String?> _uploadIdImageToRealtimeDB(String userId) async {
    if (_idImage == null) return null;
    try {
      Uint8List imageBytes = kIsWeb
          ? _idImage as Uint8List
          : await (_idImage as File).readAsBytes();
      final compressedImage = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
      );
      if (compressedImage.lengthInBytes > 1 * 1024 * 1024) {
        throw Exception('Image size exceeds 1MB limit');
      }
      final base64Image = base64Encode(compressedImage);
      await _database.child('pendingUsers/$userId/idImage').set(base64Image);
      return base64Image;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_translate('image_error')}: $e')),
      );
      return null;
    }
  }
  final Color accentColor = const Color(0xFF4AB8D8);
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();

  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _fatherNameFocus = FocusNode();
  final FocusNode _grandfatherNameFocus = FocusNode();
  final FocusNode _familyNameFocus = FocusNode();
  final FocusNode _idNumberFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  final List<GlobalKey> _showcaseKeys = [];

  final Map<String, Map<String, String>> _translations = {
    'signup_title': {'ar': 'إنشاء حساب جديد', 'en': 'Create New Account'},
    'first_name': {'ar': 'الاسم الأول', 'en': 'First Name'},
    'father_name': {'ar': 'اسم الأب', 'en': 'Father Name'},
    'grandfather_name': {'ar': 'اسم الجد', 'en': 'Grandfather Name'},
    'family_name': {'ar': 'اسم العائلة', 'en': 'Family Name'},
    'id_number': {'ar': 'رقم الهوية', 'en': 'ID Number'},
    'birth_date': {'ar': 'تاريخ الميلاد', 'en': 'Birth Date'},
    'gender': {'ar': 'الجنس', 'en': 'Gender'},
    'male': {'ar': 'ذكر', 'en': 'Male'},
    'female': {'ar': 'أنثى', 'en': 'Female'},
    'phone': {'ar': 'رقم الهاتف', 'en': 'Phone Number'},
    'address': {'ar': 'مكان السكن', 'en': 'Address'},
    'email': {'ar': 'البريد الإلكتروني', 'en': 'Email'},
    'password': {'ar': 'كلمة المرور', 'en': 'Password'},
    'confirm_password': {'ar': 'تأكيد كلمة المرور', 'en': 'Confirm Password'},
    'register_button': {'ar': 'تسجيل الحساب', 'en': 'Register'},
    'add_profile_photo': {'ar': 'إضافة صورة شخصية', 'en': 'Add Profile Photo'},
    'personal_info': {'ar': 'المعلومات الشخصية', 'en': 'Personal Information'},
    'account_info': {'ar': 'معلومات الحساب', 'en': 'Account Information'},
    'required_field': {'ar': '*', 'en': '*'},
    'select_date': {'ar': 'اختر التاريخ', 'en': 'Select date'},
    'validation_required': {
      'ar': 'هذا الحقل مطلوب',
      'en': 'This field is required',
    },
    'validation_id_length': {
      'ar': 'رقم الهوية يجب أن يكون 9 أرقام',
      'en': 'ID must be 9 digits',
    },
    'validation_phone_length': {
      'ar': 'رقم الهاتف يجب أن يكون 10 أرقام',
      'en': 'Phone must be 10 digits',
    },
    'validation_email': {
      'ar': 'البريد الإلكتروني غير صحيح',
      'en': 'Invalid email format',
    },
    'validation_password_length': {
      'ar': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      'en': 'Password must be at least 6 characters',
    },
    'validation_password_match': {
      'ar': 'كلمات المرور غير متطابقة',
      'en': 'Passwords do not match',
    },
    'validation_gender': {
      'ar': 'الرجاء اختيار الجنس',
      'en': 'Please select gender',
    },
    'register_success': {
      'ar': 'تم التسجيل بنجاح',
      'en': 'Registration successful',
    },
    'register_error': {
      'ar': 'حدث خطأ أثناء التسجيل',
      'en': 'Registration error',
    },
    'image_error': {
      'ar': 'حدث خطأ في تحميل الصورة',
      'en': 'Image upload error',
    },
    'id_exists': {
      'ar': 'رقم الهوية مسجل مسبقاً',
      'en': 'ID number already exists',
    },
    'new_account_notification': {
      'ar': 'حساب جديد يحتاج إلى موافقة',
      'en': 'New account needs approval',
    },
    'account_pending': {
      'ar': 'تم التسجيل بنجاح، ينتظر موافقة المسؤول',
      'en': 'Registration successful, waiting for admin approval',
    },

    'help_first_name': {
      'ar': 'ادخل الاسم الأول كما هو في الهوية',
      'en': 'Enter your first name as in your ID',
    },
    'help_father_name': {
      'ar': 'ادخل اسم الأب كما هو في الهوية',
      'en': 'Enter your father name as in your ID',
    },
    'help_grandfather_name': {
      'ar': 'ادخل اسم الجد كما هو في الهوية',
      'en': 'Enter your grandfather name as in your ID',
    },
    'help_family_name': {
      'ar': 'ادخل اسم العائلة كما هو في الهوية',
      'en': 'Enter your family name as in your ID',
    },
    'help_id_number': {
      'ar': 'ادخل رقم الهوية المكون من 9 أرقام',
      'en': 'Enter your 9-digit ID number',
    },
    'help_birth_date': {
      'ar': 'اختر تاريخ ميلادك من هنا',
      'en': 'Select your birth date',
    },
    'help_gender': {
      'ar': 'اختر الجنس المناسب',
      'en': 'Select your gender',
    },
    'help_phone': {
      'ar': 'ادخل رقم الهاتف المكون من 10 أرقام',
      'en': 'Enter your 10-digit phone number',
    },
    'help_address': {
      'ar': 'ادخل مكان السكن بالتفصيل',
      'en': 'Enter your full address',
    },
    'help_email': {
      'ar': 'أدخل بريدك الإلكتروني الصحيح',
      'en': 'Enter your correct email address',
    },
    'help_password': {
      'ar': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      'en': 'Password must be at least 6 characters',
    },
    'help_confirm_password': {
      'ar': 'أعد كتابة كلمة المرور للتأكيد',
      'en': 'Re-enter your password to confirm',
    },
    'help_showcase_tooltip': {
      'ar': 'شرح الحقول خطوة بخطوة',
      'en': 'Step-by-step field guide',
    },
    'showcase_image': {
      'ar': 'اضغط هنا لاختيار صورة شخصية',
      'en': 'Tap here to select a profile photo',
    },
  };

  @override
  void initState() {
    super.initState();
    _showcaseKeys.addAll([
      _imageShowcaseKey,
      _firstNameShowcaseKey,
      _fatherNameShowcaseKey,
      _grandfatherNameShowcaseKey,
      _familyNameShowcaseKey,
      _idNumberShowcaseKey,
      _birthDateShowcaseKey,
      _genderShowcaseKey,
      _phoneShowcaseKey,
      _addressShowcaseKey,
      _emailShowcaseKey,
      _passwordShowcaseKey,
      _confirmPasswordShowcaseKey,
    ]);
    
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    FocusScope.of(context).unfocus();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    
    _firstNameController.dispose();
    _fatherNameController.dispose();
    _grandfatherNameController.dispose();
    _familyNameController.dispose();
    _idNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    
    _firstNameFocus.dispose();
    _fatherNameFocus.dispose();
    _grandfatherNameFocus.dispose();
    _familyNameFocus.dispose();
    _idNumberFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    
    super.dispose();
  }

  String _translate(String key) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return _translations[key]![languageProvider.isEnglish ? 'en' : 'ar'] ?? key;
  }

  Future<bool> _checkIdNumberExists(String idNumber) async {
    try {
      final activeSnapshot = await _database
          .child('users')
          .orderByChild('idNumber')
          .equalTo(idNumber)
          .once();
      if (activeSnapshot.snapshot.value != null) return true;

      final pendingSnapshot = await _database
          .child('pendingUsers')
          .orderByChild('idNumber')
          .equalTo(idNumber)
          .once();
      return pendingSnapshot.snapshot.value != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> _sendNotificationToSecretary(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    try {
      final secretarySnapshot = await _database
          .child('users')
          .orderByChild('role')
          .equalTo('secretary')
          .once();

      if (secretarySnapshot.snapshot.value != null) {
        final Map<dynamic, dynamic> secretaries =
            secretarySnapshot.snapshot.value as Map<dynamic, dynamic>;
        final String secretaryId = secretaries.keys.first;

        final notificationRef =
            _database.child('notifications/$secretaryId').push();
        await notificationRef.set({
          'title': _translate('new_account_notification'),
          'message':
              '${userData['firstName']} ${userData['familyName']} - ${userData['idNumber']}',
          'userId': userId,
          'userData': userData,
          'timestamp': ServerValue.timestamp,
          'read': false,
          'type': 'new_account',
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_translate('image_error')}: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          if (!mounted) return;
          setState(() => _patientImage = bytes);
        } else {
          if (!mounted) return;
          setState(() => _patientImage = File(image.path));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_translate('image_error')}: $e')),
      );
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthDate) {
      setState(() => _birthDate = picked);
    }
  }

  Widget _buildIdImageWidget() {
    if (_idImage == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card, size: 50, color: primaryColor),
          const SizedBox(height: 8),
          Text(
            'إرفاق صورة الهوية',
            style: TextStyle(color: primaryColor),
          ),
        ],
      );
    }
    return kIsWeb
        ? Image.memory(
            _idImage as Uint8List,
            width: 150,
            height: 100,
            fit: BoxFit.cover,
          )
        : Image.file(
            _idImage as File,
            width: 150,
            height: 100,
            fit: BoxFit.cover,
          );
  }

  Future<String?> _uploadImageToRealtimeDB(String userId) async {
    if (_patientImage == null) return null;

    try {
      Uint8List imageBytes = kIsWeb
          ? _patientImage as Uint8List
          : await (_patientImage as File).readAsBytes();

      final compressedImage = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 800,
        minHeight: 800,
        quality: 70,
      );

      if (compressedImage.lengthInBytes > 1 * 1024 * 1024) {
        throw Exception('Image size exceeds 1MB limit');
      }

      final base64Image = base64Encode(compressedImage);
      await _database.child('pendingUsers/$userId/image').set(base64Image);
      return base64Image;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_translate('image_error')}: $e')),
      );
      return null;
    }
  }

  Future<void> _registerUser() async {

    // Check required fields and show SnackBar with missing field name
    final requiredFields = [
      {'controller': _firstNameController, 'key': 'first_name'},
      {'controller': _fatherNameController, 'key': 'father_name'},
      {'controller': _grandfatherNameController, 'key': 'grandfather_name'},
      {'controller': _familyNameController, 'key': 'family_name'},
      {'controller': _idNumberController, 'key': 'id_number'},
      {'controller': _phoneController, 'key': 'phone'},
      {'controller': _addressController, 'key': 'address'},
      {'controller': _emailController, 'key': 'email'},
      {'controller': _passwordController, 'key': 'password'},
      {'controller': _confirmPasswordController, 'key': 'confirm_password'},
    ];
    for (var field in requiredFields) {
      final controller = field['controller'] as TextEditingController?;
      final key = field['key'] as String?;
      if (controller == null || key == null) continue;
      if (controller.text.trim().isEmpty) {
        if (!mounted) return;
  final fieldName = _translate(key);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('الحقل "$fieldName" مطلوب')),
        );
        return;
      }
    }
    if (_birthDate == null) {
      if (!mounted) return;
  final birthDateName = _translate('birth_date');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('الحقل "$birthDateName" مطلوب')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (_patientImage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الصورة الشخصية مطلوبة')),
      );
      return;
    }

    if (_idImage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('صورة الهوية مطلوبة')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translate('validation_password_match'))),
      );
      return;
    }

    if (_gender == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translate('validation_gender'))),
      );
      return;
    }

    final idExists = await _checkIdNumberExists(_idNumberController.text.trim());
    if (idExists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translate('id_exists'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String? imageBase64 = await _uploadImageToRealtimeDB(userCredential.user!.uid);
      String? idImageBase64 = await _uploadIdImageToRealtimeDB(userCredential.user!.uid);

      final userData = {
        'firstName': _firstNameController.text.trim(),
        'fatherName': _fatherNameController.text.trim(),
        'grandfatherName': _grandfatherNameController.text.trim(),
        'familyName': _familyNameController.text.trim(),
        'idNumber': _idNumberController.text.trim(),
        'birthDate': _birthDate?.millisecondsSinceEpoch,
        'gender': _gender,
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'image': imageBase64,
        'idImage': idImageBase64,
        'createdAt': ServerValue.timestamp,
        'role': 'patient',
        'authUid': userCredential.user!.uid,
        'isActive': false,
      };

      await _database.child('pendingUsers/${userCredential.user!.uid}').set(userData);

      await _sendNotificationToSecretary(userCredential.user!.uid, userData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_translate('account_pending'))),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PendingPatientPage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = _translate('register_error');
      if (e.code == 'weak-password') {
        errorMessage = _translate('validation_password_length');
      } else if (e.code == 'email-already-in-use') {
        errorMessage = _translate('validation_email');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_translate('register_error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFieldShowcase(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShowCaseWidget.of(context).startShowCase([key]);
    });
  }

  Widget _buildImageWidget() {
    if (_patientImage == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 50, color: primaryColor),
          const SizedBox(height: 8),
          Text(
            _translate('add_profile_photo'),
            style: TextStyle(color: primaryColor),
          ),
        ],
      );
    }

    return kIsWeb
        ? Image.memory(
            _patientImage as Uint8List,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          )
        : Image.file(
            _patientImage as File,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int? maxLength,
    required FocusNode focusNode,
    String? helpText,
    GlobalKey? showcaseKey,
    TextInputAction? textInputAction,
    FocusNode? nextFocusNode,
    bool autofocus = false,
  }) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {
        setState(() {
          _userIsTypingOrFocused = hasFocus;
        });
      },
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength: maxLength,
        autofocus: autofocus,
        textInputAction: textInputAction,
        onFieldSubmitted: (_) {
          if (nextFocusNode != null) {
            FocusScope.of(context).requestFocus(nextFocusNode);
          } else {
            FocusScope.of(context).unfocus();
          }
        },
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: primaryColor.withAlpha(204)),
          prefixIcon: prefixIcon,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (suffixIcon != null) suffixIcon,
              if (helpText != null && showcaseKey != null)
                IconButton(
                  icon: Icon(Icons.help_outline, color: accentColor, size: 20),
                  onPressed: () {
                    _showFieldShowcase(showcaseKey);
                  },
                  tooltip: helpText,
                ),
            ],
          ),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        validator: validator,
        onTap: () {
          setState(() {
            _userIsTypingOrFocused = true;
          });
        },
      ),
    );
  }

  Widget _buildGenderRadioButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            '${_translate('gender')} ${_translate('required_field')}',
            style: TextStyle(
              color: primaryColor.withAlpha(204),

              fontSize: 16,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: Text(_translate('male')),
                value: 'male',
                groupValue: _gender,
                activeColor: primaryColor,
                onChanged: (value) => setState(() => _gender = value),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: Text(_translate('female')),
                value: 'female',
                groupValue: _gender,
                activeColor: primaryColor,
                onChanged: (value) => setState(() => _gender = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx != null) {
      FocusScope.of(context).unfocus();

      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 1), 
        curve: Curves.easeInOut,
        alignment: 0.3,
      );

      if (key == _firstNameShowcaseKey) {
        _firstNameFocus.requestFocus();
      } else if (key == _fatherNameShowcaseKey) {
        _fatherNameFocus.requestFocus();
      } else if (key == _grandfatherNameShowcaseKey) {
        _grandfatherNameFocus.requestFocus();
      } else if (key == _familyNameShowcaseKey) {
        _familyNameFocus.requestFocus();
      } else if (key == _idNumberShowcaseKey) {
        _idNumberFocus.requestFocus();
      } else if (key == _phoneShowcaseKey) {
        _phoneFocus.requestFocus();
      } else if (key == _addressShowcaseKey) {
        _addressFocus.requestFocus();
      } else if (key == _emailShowcaseKey) {
        _emailFocus.requestFocus();
      } else if (key == _passwordShowcaseKey) {
        _passwordFocus.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (!_userIsTypingOrFocused) {
          
        }
        FocusScope.of(context).unfocus();
        setState(() {
          _userIsTypingOrFocused = false;
        });
      },
      child: SignUpHelpShowcase(
        showcaseKeys: _showcaseKeys,
        onStepScroll: _scrollTo,
        child: Directionality(
          textDirection: Provider.of<LanguageProvider>(context).isEnglish
              ? TextDirection.ltr
              : TextDirection.rtl,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(_translate('signup_title')),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.language),
                  onPressed: () {
                    Provider.of<LanguageProvider>(context, listen: false)
                        .toggleLanguage();
                  },
                ),
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.help_outline, color: accentColor, size: 28),
                    tooltip: _translate('help_showcase_tooltip'),
                    onPressed: () {
                      ShowCaseWidget.of(context).startShowCase(_showcaseKeys);
                    },
                  ),
                ),
              ],
            ),
            resizeToAvoidBottomInset: true,
            body: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final isLargeScreen = screenWidth > 600;
                final screenHeight = MediaQuery.of(context).size.height;

                return Center(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(), 
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isLargeScreen ? 600 : double.infinity,
                        minHeight: isLargeScreen ? 0 : screenHeight,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Showcase(
                              key: _imageShowcaseKey,
                              description: _translate('showcase_image'),
                              child: GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    border: Border.all(color: primaryColor),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _buildImageWidget(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            GestureDetector(
                              onTap: _pickIdImage,
                              child: Container(
                                width: 150,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  border: Border.all(color: primaryColor),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildIdImageWidget(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _translate('personal_info'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Showcase(
                                    key: _firstNameShowcaseKey,
                                    description: _translate('help_first_name'),
                                    child: _buildTextFormField(
                                      controller: _firstNameController,
                                      labelText: '${_translate('first_name')} ${_translate('required_field')}',
                                      prefixIcon: Icon(Icons.person, color: accentColor),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return _translate('validation_required');
                                        }
                                        return null;
                                      },
                                      focusNode: _firstNameFocus,
                                      helpText: _translate('help_first_name'),
                                      showcaseKey: _firstNameShowcaseKey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Showcase(
                                    key: _fatherNameShowcaseKey,
                                    description: _translate('help_father_name'),
                                    child: _buildTextFormField(
                                      controller: _fatherNameController,
                                      labelText: '${_translate('father_name')} ${_translate('required_field')}',
                                      prefixIcon: Icon(Icons.person, color: accentColor),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return _translate('validation_required');
                                        }
                                        return null;
                                      },
                                      focusNode: _fatherNameFocus,
                                      helpText: _translate('help_father_name'),
                                      showcaseKey: _fatherNameShowcaseKey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Showcase(
                                    key: _grandfatherNameShowcaseKey,
                                    description: _translate('help_grandfather_name'),
                                    child: _buildTextFormField(
                                      controller: _grandfatherNameController,
                                      labelText: '${_translate('grandfather_name')} ${_translate('required_field')}',
                                      prefixIcon: Icon(Icons.person, color: accentColor),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return _translate('validation_required');
                                        }
                                        return null;
                                      },
                                      focusNode: _grandfatherNameFocus,
                                      helpText: _translate('help_grandfather_name'),
                                      showcaseKey: _grandfatherNameShowcaseKey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Showcase(
                                    key: _familyNameShowcaseKey,
                                    description: _translate('help_family_name'),
                                    child: _buildTextFormField(
                                      controller: _familyNameController,
                                      labelText: '${_translate('family_name')} ${_translate('required_field')}',
                                      prefixIcon: Icon(Icons.person, color: accentColor),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return _translate('validation_required');
                                        }
                                        return null;
                                      },
                                      focusNode: _familyNameFocus,
                                      helpText: _translate('help_family_name'),
                                      showcaseKey: _familyNameShowcaseKey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Showcase(
                                    key: _idNumberShowcaseKey,
                                    description: _translate('help_id_number'),
                                    child: _buildTextFormField(
                                      controller: _idNumberController,
                                      labelText: '${_translate('id_number')} ${_translate('required_field')}',
                                      keyboardType: TextInputType.number,
                                      maxLength: 9,
                                      prefixIcon: Icon(Icons.credit_card, color: accentColor),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return _translate('validation_required');
                                        }
                                        if (value.length < 9) {
                                          return _translate('validation_id_length');
                                        }
                                        return null;
                                      },
                                      focusNode: _idNumberFocus,
                                      helpText: _translate('help_id_number'),
                                      showcaseKey: _idNumberShowcaseKey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Showcase(
                                    key: _birthDateShowcaseKey,
                                    description: _translate('help_birth_date'),
                                    child: InkWell(
                                      onTap: _selectBirthDate,
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: '${_translate('birth_date')} ${_translate('required_field')}',
                                          labelStyle: TextStyle(color: primaryColor.withAlpha(204)),

                                          prefixIcon: Icon(Icons.calendar_today, color: accentColor),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                        ),
                                        child: Text(
                                          _birthDate == null
                                              ? _translate('select_date')
                                              : DateFormat('yyyy-MM-dd').format(_birthDate!),
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: _birthDate == null ? Colors.grey[600] : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Showcase(
                                    key: _genderShowcaseKey,
                                    description: _translate('help_gender'),
                                    child: _buildGenderRadioButtons(),
                                  ),
                                  const SizedBox(height: 10),
                                  Showcase(
                                    key: _phoneShowcaseKey,
                                    description: _translate('help_phone'),
                                    child: _buildTextFormField(
                                      controller: _phoneController,
                                      labelText: '${_translate('phone')} ${_translate('required_field')}',
                                      keyboardType: TextInputType.phone,
                                      maxLength: 10,
                                      prefixIcon: Icon(Icons.phone, color: accentColor),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return _translate('validation_required');
                                        }
                                        if (value.length < 10) {
                                          return _translate('validation_phone_length');
                                        }
                                        return null;
                                      },
                                      focusNode: _phoneFocus,
                                      helpText: _translate('help_phone'),
                                      showcaseKey: _phoneShowcaseKey,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Showcase(
                                    key: _addressShowcaseKey,
                                    description: _translate('help_address'),
                                    child: _buildTextFormField(
                                      controller: _addressController,
                                      labelText: '${_translate('address')} ${_translate('required_field')}',
                                      prefixIcon: Icon(Icons.location_on, color: accentColor),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return _translate('validation_required');
                                        }
                                        return null;
                                      },
                                      focusNode: _addressFocus,
                                      helpText: _translate('help_address'),
                                      showcaseKey: _addressShowcaseKey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _translate('account_info'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Showcase(
                                    key: _emailShowcaseKey,
                                    description: _translate('help_email'),
                                    child: _buildTextFormField(
                                      controller: _emailController,
                                      labelText: '${_translate('email')} ${_translate('required_field')}',
                                      keyboardType: TextInputType.emailAddress,
                                      prefixIcon: Icon(Icons.email, color: accentColor),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return _translate('validation_required');
                                        }
                                        if (!value.contains('@')) {
                                          return _translate('validation_email');
                                        }
                                        return null;
                                      },
                                      focusNode: _emailFocus,
                                      helpText: _translate('help_email'),
                                      showcaseKey: _emailShowcaseKey,
                                      textInputAction: TextInputAction.next,
                                      nextFocusNode: _passwordFocus,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Showcase(
                                    key: _passwordShowcaseKey,
                                    description: _translate('help_password'),
                                    child: _buildTextFormField(
                                      controller: _passwordController,
                                      labelText: '${_translate('password')} ${_translate('required_field')}',
                                      obscureText: true,
                                      prefixIcon: Icon(Icons.lock, color: accentColor),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return _translate('validation_required');
                                        }
                                        if (value.length < 6) {
                                          return _translate('validation_password_length');
                                        }
                                        return null;
                                      },
                                      focusNode: _passwordFocus,
                                      helpText: _translate('help_password'),
                                      showcaseKey: _passwordShowcaseKey,
                                      textInputAction: TextInputAction.next,
                                      nextFocusNode: _confirmPasswordFocus,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Showcase(
                                    key: _confirmPasswordShowcaseKey,
                                    description: _translate('help_confirm_password'),
                                    child: _buildTextFormField(
                                      controller: _confirmPasswordController,
                                      labelText: '${_translate('confirm_password')} ${_translate('required_field')}',
                                      obscureText: true,
                                      prefixIcon: Icon(Icons.lock_outline, color: accentColor),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return _translate('validation_required');
                                        }
                                        if (value != _passwordController.text) {
                                          return _translate('validation_password_match');
                                        }
                                        return null;
                                      },
                                      focusNode: _confirmPasswordFocus,
                                      helpText: _translate('help_confirm_password'),
                                      showcaseKey: _confirmPasswordShowcaseKey,
                                      textInputAction: TextInputAction.done,
                                      nextFocusNode: null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _registerUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        _translate('register_button'),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ));
                },
              ),
            ),
          ),
        ),
      );
    
  }
}