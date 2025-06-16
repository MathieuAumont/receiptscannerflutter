import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:receipt_scanner_flutter/theme/app_theme.dart';
import 'package:receipt_scanner_flutter/providers/language_provider.dart';
import 'package:receipt_scanner_flutter/providers/receipt_provider.dart';
import 'package:receipt_scanner_flutter/services/ai_service.dart';
import 'package:receipt_scanner_flutter/widgets/modern_app_bar.dart';
import 'package:receipt_scanner_flutter/models/receipt.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isAnalyzing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) {
          setState(() {
            _error = 'No cameras available on this device';
          });
        }
        return;
      }

      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
      );

      try {
        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Failed to initialize camera: $e';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to get camera list: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final image = await _controller!.takePicture();
      // Process the image here
      await _processImage(image.path);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to take picture: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        await _processImage(image.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to pick image: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _processImage(String imagePath) async {
    try {
      // Convert image to base64
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      // Analyze receipt with AI
      final receiptData = await AIService.analyzeReceipt(base64Image);

      // Create receipt from AI analysis
      final receipt = Receipt(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        company: receiptData['merchant'] ?? 'Unknown',
        date: DateTime.tryParse(receiptData['date'] ?? '') ?? DateTime.now(),
        items: (receiptData['items'] as List?)?.map((item) => ReceiptItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_${item['name']}',
          name: item['name'] ?? 'Unknown',
          price: (item['price'] ?? 0.0).toDouble(),
          quantity: (item['quantity'] ?? 1).toInt(),
        )).toList() ?? [],
        subtotal: (receiptData['subtotal'] ?? 0.0).toDouble(),
        taxes: Taxes(
          tps: (receiptData['tps'] ?? 0.0).toDouble(),
          tvq: (receiptData['tvq'] ?? 0.0).toDouble(),
        ),
        totalAmount: (receiptData['total'] ?? 0.0).toDouble(),
        category: receiptData['category'] ?? 'other',
        metadata: ReceiptMetadata(
          processedAt: DateTime.now(),
          ocrEngine: 'gpt-4o',
          version: '1.0',
          confidence: (receiptData['confidence'] ?? 0.0).toDouble(),
        ),
      );

      // Save receipt
      if (!mounted) return;
      final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
      await receiptProvider.addReceipt(receipt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt processed successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to process receipt: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (_error != null) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: ModernAppBar(
            title: languageProvider.translate('scan_receipt'),
            showBackButton: true,
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 64,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                _error!,
                style: TextStyle(color: AppTheme.errorColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingM),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                    _isInitialized = false;
                  });
                  _initializeCamera();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: ModernAppBar(
            title: languageProvider.translate('scan_receipt'),
            showBackButton: true,
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: AppTheme.spacingM),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          
          // Overlay
          if (_isAnalyzing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: AppTheme.spacingM),
                    Text(
                      'Analyzing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingXXL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery Button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      onPressed: _isAnalyzing ? null : _pickImage,
                      icon: const Icon(
                        LucideIcons.image,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  // Capture Button
                  GestureDetector(
                    onTap: _isAnalyzing ? null : _takePicture,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 4,
                        ),
                      ),
                      child: _isAnalyzing
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  
                  // Placeholder for symmetry
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          
          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + AppTheme.spacingM,
            left: AppTheme.spacingM,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  LucideIcons.arrowLeft,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}