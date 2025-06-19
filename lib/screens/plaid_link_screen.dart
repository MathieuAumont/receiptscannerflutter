import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:receipt_scanner_flutter/providers/plaid_provider.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/widgets/modern_app_bar.dart';

class PlaidLinkScreen extends StatefulWidget {
  final String linkToken;

  const PlaidLinkScreen({
    super.key,
    required this.linkToken,
  });

  @override
  State<PlaidLinkScreen> createState() => _PlaidLinkScreenState();
}

class _PlaidLinkScreenState extends State<PlaidLinkScreen> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    // Créer l'URL Plaid Link avec le token
    final plaidUrl = 'https://cdn.plaid.com/link/v2/stable/link.html'
        '?link_token=${widget.linkToken}'
        '&is_mobile_app=true';

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
            
            // Injecter du JavaScript pour écouter les événements Plaid
            _controller.runJavaScript('''
              window.addEventListener('message', function(event) {
                if (event.data.type === 'plaid_link_success') {
                  window.location.href = 'plaid://success?public_token=' + event.data.public_token;
                } else if (event.data.type === 'plaid_link_exit') {
                  window.location.href = 'plaid://exit';
                }
              });
            ''');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('plaid://success')) {
              final uri = Uri.parse(request.url);
              final publicToken = uri.queryParameters['public_token'];
              if (publicToken != null) {
                _handleSuccess(publicToken);
              }
              return NavigationDecision.prevent;
            } else if (request.url.startsWith('plaid://exit')) {
              Navigator.of(context).pop(false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(plaidUrl));
  }

  Future<void> _handleSuccess(String publicToken) async {
    final plaidProvider = Provider.of<PlaidProvider>(context, listen: false);
    final success = await plaidProvider.exchangePublicToken(publicToken);
    
    if (mounted) {
      Navigator.of(context).pop(success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ModernAppBar(
          title: 'Connexion bancaire Plaid',
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🏦', style: TextStyle(fontSize: 48)),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement de Plaid Link...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connexion sécurisée à votre banque',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}