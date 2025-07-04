import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // Rive State Machineの入力
  SMIBool? _isJumpingInput;
  SMITrigger? _jumpTriggerInput;

  // StateMachineControllerを保持するための変数
  // これを初期化はRiveAnimation.assetのonInitで行います
  StateMachineController? _stateMachineController;

  @override
  void dispose() {
    // StateMachineControllerをdisposeすることを忘れずに
    _stateMachineController?.dispose();
    super.dispose();
  }

  void _onRiveInit(Artboard artboard) {
    // State Machineを探し、コントローラーを初期化
    _stateMachineController = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1', // Riveエディタで設定したState Machineの名前
    );

    if (_stateMachineController != null) {
      artboard.addController(_stateMachineController!);

      // State Machineから入力（Input）を取得し、型をキャスト
      // Riveエディタで設定した入力名に合わせて変更してください
      _isJumpingInput = _stateMachineController!.findInput<bool>('isCorrect') as SMIBool?;
    }
  }

  void _toggleJump() {
    // Boolean入力の値を切り替える例
    if (_isJumpingInput != null) {
      _isJumpingInput!.value = !_isJumpingInput!.value;
      print('isJumping: ${_isJumpingInput!.value}');
    }
  }

  void _triggerJump() {
    // Triggerを起動する例
    if (_jumpTriggerInput != null) {
      _jumpTriggerInput!.fire(); // Triggerを発火させる
      print('Jump triggered!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rive Animation Control')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: RiveAnimation.asset(
                'assets/cat.riv', // あなたのRiveファイルへのパス
                onInit: _onRiveInit, // ここでonInitコールバックを使用
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleJump,
              child: const Text('Toggle Jump (Boolean)'),
            ),
            ElevatedButton(
              onPressed: _triggerJump,
              child: const Text('Trigger Jump (Trigger)'),
            ),
          ],
        ),
      ),
    );
  }
}