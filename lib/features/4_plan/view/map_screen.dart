import 'package:flutter/material.dart';

import 'package:fyp_proj/features/4_plan/model/plan_model.dart';
import 'package:webview_flutter/webview_flutter.dart'; // ← この行を追加

class MapScreen extends StatefulWidget {
  final TravelStep? origin;
  final TravelStep destination;

  const MapScreen({super.key, this.origin, required this.destination});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 正しいGoogleマップのURLを組み立てる
    final Uri mapUri = _buildMapUri();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print("Web view error: ${error.description}");
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              // ユーザーにエラーメッセージを表示することも可能
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Map could not be loaded: ${error.description}')),
              );
            }
          },
        ),
      )
      ..loadRequest(mapUri); // 組み立てたURLを読み込む
  }

  Uri _buildMapUri() {
    final origin = widget.origin;
    final destination = widget.destination;

    if (origin != null) {
      // 出発地と目的地の両方がある場合：経路検索URL
      final originCoords = '${origin.location.latitude},${origin.location.longitude}';
      final destinationCoords = '${destination.location.latitude},${destination.location.longitude}';
      // 正しいウェブサイトのURL形式を使用
      print("Looking up the url: ${Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$originCoords&destination=$destinationCoords'
      )}");
      return Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$originCoords&destination=$destinationCoords'
      );
    } else {
      // 目的地のみの場合：場所検索URL
      final query = Uri.encodeComponent(destination.placeName);
      // 正しいウェブサイトのURL形式を使用
      return Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query&query_place_id=${destination.placeId}'
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.origin?.placeName ?? "Map"} → ${widget.destination.placeName}'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

}