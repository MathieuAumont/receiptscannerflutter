import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/services/ai_service.dart';
import 'package:go_router/go_router.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _questionController = TextEditingController();
  String? _answer;
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _analyzeSpending() async {
    if (_questionController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _answer = null;
    });

    try {
      final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
      final spendingData = {
        'totalSpending': receiptProvider.totalSpending,
        'receipts': receiptProvider.receipts.map((r) => {
          'date': r.date.toIso8601String(),
          'amount': r.totalAmount,
          'category': r.category,
          'merchant': r.company,
        }).toList(),
        'categoryTotals': receiptProvider.getCategoryTotals(),
      };

      final analysis = await AIService.analyzeSpending(
        _questionController.text.trim(),
        spendingData,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _answer = analysis;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _answer = 'Error analyzing spending: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analysis'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/reports'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ask a question about your spending',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Examples:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 8),
            
            ...const [
              '• What is my total spending this month?',
              '• Which category did I spend the most on?',
              '• Compare my spending over the last 3 months',
              '• How can I reduce my expenses?',
            ].map((example) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                example,
                style: TextStyle(color: Colors.grey[600]),
              ),
            )),
            
            const SizedBox(height: 24),
            
            // Question Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Ask your question here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: _isLoading ? null : _analyzeSpending,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            LucideIcons.send,
                            color: Colors.white,
                          ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Loading State
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyzing your spending data...'),
                  ],
                ),
              ),
            
            // Answer
            if (_answer != null && !_isLoading)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.brain,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI Analysis',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _answer!,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}