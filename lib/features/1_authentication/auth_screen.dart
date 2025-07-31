import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignInModal extends StatefulWidget {
  const SignInModal({super.key});

  @override
  State<SignInModal> createState() => _SignInModalState();
}

class _SignInModalState extends State<SignInModal> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSigningIn = false;

  // Handles the entire sign-in flow and provides feedback to the user.
  Future<void> _handleSignIn(Future<UserCredential?> signInMethod) async {
    setState(() {
      _isSigningIn = true;
    });

    try {
      final userCredential = await signInMethod;
      // If sign-in is successful and we have a user, close the modal.
      if (userCredential?.user != null && mounted) {
        print("Signed in: ${userCredential!.user!.displayName}");
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors
      print("Firebase Auth Error: ${e.message}");
      _showErrorSnackbar("Sign-in failed. ${e.message}");
    } catch (e) {
      // Handle other errors (e.g., network, user cancellation)
      print("General Error: $e");
      // Check if the sign-in was cancelled by the user
      if (e is Exception && e.toString().contains('cancelled')) {
        _showErrorSnackbar("Sign-in cancelled.");
      } else {
        _showErrorSnackbar("An unexpected error occurred. Please try again.");
      }
    } finally {
      // Ensure the loading state is always turned off.
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }
  
  void _showErrorSnackbar(String message) {
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<UserCredential?> _signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    // If the user cancelled or there's no auth detail, return null.
    if (googleAuth == null) {
        throw Exception('Google sign-in cancelled or failed.');
    }

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await _auth.signInWithCredential(credential);
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child:Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Sign In to Continue',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (_isSigningIn)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: CircularProgressIndicator(),
            )
          else
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _handleSignIn(_signInWithGoogle()),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          const SizedBox(height: 10),
        ],
      ),
    ));
  }
}