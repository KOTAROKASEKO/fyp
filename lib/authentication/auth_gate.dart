import 'package:flutter/material.dart';
import 'package:fyp_proj/authentication/forgotpassword.dart';
import 'package:fyp_proj/landing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// The AuthGate is now a StatefulWidget to handle state changes.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
  // Add this method to handle Google sign-in
  }

class _AuthGateState extends State<AuthGate> {
  // Text editing controllers to capture user input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State variables for loading and error messages
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<User?> signinwithGoogle() async {
    try {
      // Import the necessary packages at the top if not already:
      // import 'package:google_sign_in/google_sign_in.dart';
      // import 'package:firebase_auth/firebase_auth.dart';

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      login();
      return userCredential.user;
    } catch (e) {
      throw Exception('Google sign-in failed: $e');
    }
  }

  login(){
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LandingPage()),
    );
  }

  // --- Authentication Logic ---

  Future<void> _authenticate({required bool isSignIn}) async {
    // Prevent multiple auth requests
    if (_isLoading) return;

    // Start loading and clear previous errors
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = FirebaseAuth.instance;
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (isSignIn) {
        // Sign In Logic
        await auth.signInWithEmailAndPassword(email: email, password: password);
        login();
      } else {
        // Sign Up Logic
        if (password != _confirmPasswordController.text) {
          throw 'Passwords do not match.';
        }
        await auth.createUserWithEmailAndPassword(email: email, password: password);
      }
      // After successful authentication, you would typically navigate to the home screen.
      // Navigator.of(context).pushReplacement(...);

    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors with user-friendly messages
      setState(() {
        _errorMessage = _mapFirebaseAuthException(e);
      });
    } catch (e) {
      // Handle other errors (like password mismatch)
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      // Stop loading
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Maps Firebase error codes to more readable messages
  String _mapFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
  
  // --- UI Build Methods ---

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 152, 158, 236), Color.fromARGB(255, 105, 97, 210)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Modern lock icon from the previous version
                      Container(
                        alignment: Alignment.center,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Material(
                          elevation: 8,
                          shape: const CircleBorder(),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              size: 48,
                              color: const Color(0xFF4D43E4),
                            ),
                          ),
                        ),
                      ),
                      Text('Welcome Back!',
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      _buildCard(context),
                      
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias, // Ensures gradient is clipped to rounded corners
      child: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
        colors: [Color.fromARGB(255, 163, 168, 255), Color.fromARGB(255, 92, 114, 152)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
        children: [
          _buildTabBar(),
          const SizedBox(height: 16),
          // Widget to display error message if it exists
          if (_errorMessage != null) ...[
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ],
          _buildTabBarView(),
        ],
        ),
      ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF4D43E4),
      ),
      indicatorPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey.shade600,
      tabs: const [
        Tab(text: '   Sign In   '),
        Tab(text: '   Sign Up   '),
      ],
    );
  }

  Widget _buildTabBarView() {
    return SizedBox(
      
      // Adjusted height to accommodate potential error messages
      height: 340,
      child: TabBarView(
        children: [
          _buildSignInForm(),
          _buildSignUpForm(),
        ],
      ),
    );
  }

  Widget _buildSignInForm() {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child:Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: true),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForgotPassword()),
              );
            },
            child: const Text('Forgot Password?'),
          ),
        ),
        const SizedBox(height: 20,), // Pushes the button to the bottom
        _buildAuthButton(label: 'Sign In', isSignIn: true),
        _buildGoogleSignInButton(),
      ],
    )
  );}

  Widget _buildSignUpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: true),
        const SizedBox(height: 16),
        _buildTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock_outline,
            obscureText: true),
        const Spacer(), // Pushes the button to the bottom
        _buildAuthButton(label: 'Create Account', isSignIn: false),
      ],
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
  
  // The button now displays a loading indicator when authenticating.
  Widget _buildAuthButton({required String label, required bool isSignIn}) {
    return ElevatedButton(
      onPressed: _isLoading ? null : () => _authenticate(isSignIn: isSignIn),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: const Color(0xFF4D43E4),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
  
  Widget _buildGoogleSignInButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : () {
          signinwithGoogle().then((user) {
            if (user != null) {
              // Navigate to home screen or perform any action after successful sign-in
              // Navigator.of(context).pushReplacementNamed('/home');
            }
          }).catchError((error) {
            setState(() {
              _errorMessage = error.toString();
            });
          });
        },
        icon: Image.asset(
          'assets/google_logo.png',
          height: 24,
          width: 24,
        ),
        label: const Text(
          'Sign in with Google',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Colors.black12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
      ),
    );
  }
}
