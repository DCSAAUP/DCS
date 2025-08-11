import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../loginpage.dart';

class RoleGuard extends StatefulWidget {
  final UserRole allowedRole;
  final Widget child;
  const RoleGuard({super.key, required this.allowedRole, required this.child});

  @override
  State<RoleGuard> createState() => _RoleGuardState();
}

class _RoleGuardState extends State<RoleGuard> {
  bool _checking = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _redirect();
      return;
    }
    final dbRef = FirebaseDatabase.instance.ref();
    final snapshot = await dbRef.child('users').orderByChild('email').equalTo(user.email).once();
    if (snapshot.snapshot.value == null) {
      _redirect();
      return;
    }
    final data = (snapshot.snapshot.value as Map).values.first;
    final role = data['role']?.toString().toLowerCase();
    setState(() {
      _allowed = role == widget.allowedRole.name;
      _checking = false;
    });
    if (!_allowed) _redirect();
  }

  void _redirect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _allowed ? widget.child : const SizedBox.shrink();
  }
}
