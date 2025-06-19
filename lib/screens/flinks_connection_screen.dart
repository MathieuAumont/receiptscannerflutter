import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:receipt_scanner_flutter/providers/flinks_provider.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/widgets/modern_app_bar.dart';

class FlinksConnectionScreen extends StatefulWidget {
  final String loginUrl;
  final String requestId;

  const FlinksConnectionScreen({
    super.key,
    required this.loginUrl,
    required this.requestId,
  });

  @override
  State<FlinksConnectionScreen> createState() => _FlinksConnectionScreenState();
}

class _FlinksConnectionScreenState extends State<FlinksConnectionScreen> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            
            // Vérifier si la connexion est terminée
            if (url.contains('success') || url.contains('complete')) {
              _checkConnectionStatus();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('success') || request.url.contains('complete')) {
              _checkConnectionStatus();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.loginUrl));
  }

  Future<void> _checkConnectionStatus() async {
    final flinksProvider = Provider.of<FlinksProvider>(context, listen: false);
    final success = await flinksProvider.checkConnectionStatus(widget.requestId);
    
    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ModernAppBar(
          title: 'Connexion bancaire',
          showBackButton: true,
          onBackPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Chargement de la page de connexion...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}