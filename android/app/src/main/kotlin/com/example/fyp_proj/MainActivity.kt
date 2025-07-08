package com.example.fyp_proj // この行はあなたのプロジェクトのものをそのまま使います

import android.os.Bundle // Bundleをインポート
import android.util.Log // Logをインポート
import com.google.firebase.FirebaseApp // FirebaseAppをインポート
import com.google.firebase.appcheck.FirebaseAppCheck // AppCheckをインポート
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory // Debug Providerをインポート
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // --- ここからが重要な追加コード ---
        Log.d("KOTARO_DEBUG", "MainActivity.onCreate: Initializing NATIVE App Check directly.")

        // ネイティブ側でFirebaseを初期化
        FirebaseApp.initializeApp(this)
        val firebaseAppCheck = FirebaseAppCheck.getInstance()

        // ネイティブ側でデバッグプロバイダーをインストール
        firebaseAppCheck.installAppCheckProviderFactory(
            DebugAppCheckProviderFactory.getInstance()
        )

        // トークンを強制的に取得し、ログに出力
        firebaseAppCheck.getAppCheckToken(true)
            .addOnSuccessListener { token ->
                if (token != null && token.token.isNotEmpty()) {
                    // 成功した場合、非常に目立つログを出力
                    Log.e("KOTARO_APP_CHECK_TOKEN", ">>>>>>>>>> NATIVE DEBUG TOKEN FOUND <<<<<<<<<<")
                    Log.e("KOTARO_APP_CHECK_TOKEN", "TOKEN: " + token.token)
                    Log.e("KOTARO_APP_CHECK_TOKEN", ">>>>>>>>>> COPY THE TOKEN ABOVE <<<<<<<<<<")
                } else {
                    Log.e("KOTARO_DEBUG", "Failed to get token, it was null or empty.")
                }
            }
            .addOnFailureListener { exception ->
                Log.e("KOTARO_DEBUG", "Native getAppCheckToken failed!", exception)
            }
        // --- ここまで ---
    }
}