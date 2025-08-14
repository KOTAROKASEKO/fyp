import "package:flutter/material.dart";
import "package:fyp_proj/features/1_authentication/auth_screen.dart";

// どのクラスからでも呼び出せるグローバル関数
void showSignInModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext bc) {
      return const SignInModal();
    },
  );
}

Future<bool?> showSignOutModal(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    builder: (BuildContext bc) {
      return const SignOutModal();
    },
  );
}