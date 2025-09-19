import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Access the Supabase client
final supabase = Supabase.instance.client;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() { _isLoading = true; });
    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _signUp() async {
    setState(() { _isLoading = true; });
    try {
      // For sign up, we add user metadata like full_name and role.
      await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'full_name': 'New User', 'role': 'veteran'},
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Success! Please check your email for a confirmation link.'),
        backgroundColor: Colors.green,
      ));
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wounded Heroes Login')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(onPressed: _signIn, child: const Text('Sign In')),
          TextButton(onPressed: _signUp, child: const Text('Sign Up')),
        ],
      ),
    );
  }
}