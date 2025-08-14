import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fyp_proj/firebase_service.dart/FirebaseApi.dart'; // Assuming you have this file
import 'package:google_sign_in/google_sign_in.dart';

class SignInModal extends StatefulWidget {
  const SignInModal({super.key});

  @override
  State<SignInModal> createState() => _SignInModalState();
}

class _SignInModalState extends State<SignInModal> {
  
  bool _isSigningIn = false;

  Future<UserCredential?> _signInWithGoogle() async {
  // 1. Begin the Google Sign-In process
    try {
      
      await GoogleSignIn.instance.initialize(
        serverClientId: "965355667703-7md7nnua0qk4jafafle96rqqc9v7sukv.apps.googleusercontent.com",
      );
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

      if (googleUser == null) {
        return null;
      }

      final googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      final authClient = googleUser.authorizationClient;
      final GoogleSignInClientAuthorization? clientAuth =
          await authClient.authorizeScopes(['email']);
      final String? accessToken = clientAuth?.accessToken;

      // 4. Check if both tokens were successfully retrieved.
      if (accessToken == null) {
        throw 'Failed to get access token from Google.';
      }
      if (idToken == null) {
        throw 'Failed to get id token from Google.';
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      await uploadFcm();
      return await FirebaseAuth.instance.signInWithCredential(credential);


    } catch (error) {
      print("Error during Google Sign-In: $error");
      return null;
    }
  }

  Future<void> uploadFcm() async{
    FcmService().saveTokenToDatabase(
      await FirebaseMessaging.instance.getToken() ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
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
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

}

class SignOutModal extends StatefulWidget {

  const SignOutModal({super.key});

  @override
  State<SignOutModal> createState() => _SignOutModalState();
}

class _SignOutModalState extends State<SignOutModal> {
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Are you sure you want to sign out?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // **FIX:** Use disconnect to revoke tokens and sign out from Google.
                await GoogleSignIn.instance.disconnect();
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sign out successful.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}