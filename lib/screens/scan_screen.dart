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
import 'package:go_router/go_router.dart';
import 'package:receipt_scanner_flutter/screens/manual_entry_screen.dart';
import 'package:receipt_scanner_flutter/providers/category_provider.dart';
import 'package:receipt_scanner_flutter/models/category.dart';

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
          final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
          setState(() {
            _error = languageProvider.translate('no_cameras_available');
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
          final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
          setState(() {
            _error = languageProvider.translate('failed_initialize_camera');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        setState(() {
          _error = languageProvider.translate('failed_get_camera_list');
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
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        setState(() {
          _error = languageProvider.translate('failed_take_picture');
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
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        setState(() {
          _error = languageProvider.translate('failed_pick_image');
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

      // Gestion des taxes : si 'taxes' global mais pas tps/tvq, répartir
      double tps = (receiptData['tps'] ?? 0.0).toDouble();
      double tvq = (receiptData['tvq'] ?? 0.0).toDouble();
      if ((tps == 0.0 && tvq == 0.0) && receiptData['taxes'] != null) {
        final totalTaxes = (receiptData['taxes'] ?? 0.0).toDouble();
        // TPS = 5%, TVQ = 9.975% du sous-total (Québec)
        // Répartition proportionnelle
        final tpsRate = 0.05;
        final tvqRate = 0.09975;
        final totalRate = tpsRate + tvqRate;
        tps = totalTaxes * (tpsRate / totalRate);
        tvq = totalTaxes * (tvqRate / totalRate);
      }

      // Récupérer toutes les catégories (custom + défaut)
      final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
      final allCategories = categoryProvider.categories;
      String categoryId = 'other';
      if (receiptData['category'] != null) {
        final found = CategoryService.findCategoryByName(allCategories, receiptData['category']);
        if (found != null) categoryId = found.id;
      }

      // Création du Receipt (avec id unique)
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
          tps: tps,
          tvq: tvq,
        ),
        totalAmount: (receiptData['total'] ?? 0.0).toDouble(),
        category: categoryId,
        metadata: ReceiptMetadata(
          processedAt: DateTime.now(),
          ocrEngine: 'gpt-4o',
          version: '1.0',
          confidence: (receiptData['confidence'] ?? 0.0).toDouble(),
        ),
      );

      // Ajout immédiat dans le provider
      final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
      await receiptProvider.addReceipt(receipt);

      // Ouvre la page de modification
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ManualEntryScreen(receipt: receipt),
        ),
      );
    } catch (e) {
      if (mounted) {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        setState(() {
          _error = languageProvider.translate('failed_process_receipt');
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
                onPressed: () => context.go('/home'),
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