import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:developer' as developer;
import 'dart:convert';
import '../services/classifier.dart';

class ClassificationScreen extends StatefulWidget {
  final String? selectedClassName;

  const ClassificationScreen({super.key, this.selectedClassName});

  @override
  State<ClassificationScreen> createState() => _ClassificationScreenState();
}

class _ClassificationScreenState extends State<ClassificationScreen> {
  late ImageClassifier _classifier;
  late CameraController _cameraController;
  late List<CameraDescription> cameras;
  
  bool _isModelLoaded = false;
  bool _isClassifying = false;
  bool _showCameraPreview = false;
  List<ClassificationResult> _results = [];
  String? _selectedImagePath;
  bool _isCameraInitialized = false;
  int _currentCameraIndex = 0;
  bool _isSendingToDatabase = false;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  FlashMode _flashMode = FlashMode.off;
  bool _showPhotoConfirmation = false;
  Uint8List? _capturedImageBytes;
  
  final Map<String, Map<String, dynamic>> _classificationHistory = {};
  List<Map<String, dynamic>> _recentScans = [];
  
  List<ClassificationResult> _getDisplayResults() {
    if (widget.selectedClassName == null) {
      return _results;
    }
    return _results
        .where((result) => result.label.toLowerCase() == widget.selectedClassName!.toLowerCase())
        .toList();
  }
  
  static const Map<String, String> _classDescriptions = {
    'adobe photos': 'Professional photo editing with AI-powered enhancement and cloud integration',
    'canva': 'Easy-to-use graphic design platform with millions of templates and elements',
    'fotor': 'Online photo editor with AI tools, filters, and batch processing capabilities',
    'lightroom': 'Adobe\'s comprehensive photo management and editing application',
    'picsart': 'Creative mobile editor with millions of stickers, filters, and art effects',
    'pixlr': 'Advanced photo editing suite with layers and professional tools',
    'polarr': 'Real-time photo editing with AI filters and professional capabilities',
    'remini': 'AI-powered upscaling and enhancement for low-quality photos',
    'snapseed': 'Google\'s professional photo editor with selective editing tools',
    'vsco': 'Minimalist photo editor with aesthetic filters and community features',
  };
  
  @override
  void initState() {
    super.initState();
    _loadClassificationHistory();
    _initializeApp();
  }

  Future<void> _loadClassificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('classification_history');
    
    if (historyJson != null) {
      try {
        final decoded = jsonDecode(historyJson) as Map<String, dynamic>;
        final historyMap = decoded.map((key, value) {
          final map = value as Map<String, dynamic>;
          return MapEntry(key, {
            'count': map['count'] as int,
            'totalConfidence': map['totalConfidence'] as double,
            'results': List<double>.from(map['results'] as List),
          });
        });
        _classificationHistory.addAll(historyMap);
      } catch (e) {
        developer.log('Error loading classification history: $e');
      }
    }

    final recentScansJson = prefs.getString('scan_history_list');
    if (recentScansJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(recentScansJson);
        _recentScans = decoded.map((e) => e as Map<String, dynamic>).toList();
      } catch (e) {
        developer.log('Error loading recent scans: $e');
      }
    }
  }

  Future<void> _saveClassificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(_classificationHistory);
    await prefs.setString('classification_history', historyJson);
    
    final recentScansJson = jsonEncode(_recentScans);
    await prefs.setString('scan_history_list', recentScansJson);
  }

  Future<void> _initializeApp() async {
    _classifier = ImageClassifier();
    await _loadModel();
    await _initializeCamera();
  }

  Future<void> _loadModel() async {
    try {
      await _classifier.loadModel();
      if (mounted) {
        setState(() {
          _isModelLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load model: $e')),
        );
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.medium,
          imageFormatGroup: ImageFormatGroup.yuv420,
        );
        await _cameraController.initialize();
        await _cameraController.lockCaptureOrientation();
        
        _minZoom = await _cameraController.getMinZoomLevel();
        _maxZoom = await _cameraController.getMaxZoomLevel();
        _currentZoom = _minZoom;
        
        await _cameraController.setFlashMode(FlashMode.off);
        
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }

  void _showCameraPreviewDialog() {
    if (!_isCameraInitialized || _isClassifying || !_isModelLoaded) return;
    
    setState(() => _showCameraPreview = true);
  }

  Future<void> _capturePhoto() async {
    if (_isClassifying) return;
    
    try {
      final image = await _cameraController.takePicture();
      final imageBytes = await image.readAsBytes();
      
      if (mounted) {
        setState(() {
          _selectedImagePath = image.path;
          _capturedImageBytes = imageBytes;
          _showPhotoConfirmation = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }
  
  Future<void> _confirmAndClassifyPhoto() async {
    if (_capturedImageBytes == null) return;
    
    try {
      setState(() => _isClassifying = true);
      await _classifyImage(_capturedImageBytes!);
      if (mounted) {
        setState(() {
          _showPhotoConfirmation = false;
          _showCameraPreview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Classification error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClassifying = false);
      }
    }
  }
  
  void _retakePhoto() {
    setState(() {
      _showPhotoConfirmation = false;
      _capturedImageBytes = null;
    });
  }

  void _closeCameraPreview() {
    setState(() => _showCameraPreview = false);
  }

  void _retakeClassification() {
    setState(() {
      _results = [];
      _selectedImagePath = null;
      _capturedImageBytes = null;
      _showPhotoConfirmation = false;
      _showCameraPreview = false;
    });
  }

  Future<void> _switchCamera() async {
    if (cameras.isEmpty) return;
    
    try {
      _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;
      
      await _cameraController.dispose();
      _cameraController = CameraController(
        cameras[_currentCameraIndex],
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _cameraController.initialize();
      await _cameraController.lockCaptureOrientation();
      
      _minZoom = await _cameraController.getMinZoomLevel();
      _maxZoom = await _cameraController.getMaxZoomLevel();
      _currentZoom = _minZoom;
      _flashMode = FlashMode.off;
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera switch failed: $e')),
        );
      }
    }
  }

  Future<void> _toggleFlash() async {
    try {
      final newMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      await _cameraController.setFlashMode(newMode);
      setState(() {
        _flashMode = newMode;
      });
    } catch (e) {
      developer.log('Flash toggle error: $e');
    }
  }

  Future<void> _setZoom(double zoom) async {
    if (!_isCameraInitialized) return;
    try {
      await _cameraController.setZoomLevel(zoom);
      setState(() {
        _currentZoom = zoom;
      });
    } catch (e) {
      developer.log('Zoom error: $e');
    }
  }

  Future<void> _zoomIn() async {
    final newZoom = (_currentZoom + (_maxZoom - _minZoom) * 0.1).clamp(_minZoom, _maxZoom);
    await _setZoom(newZoom);
  }

  Future<void> _zoomOut() async {
    final newZoom = (_currentZoom - (_maxZoom - _minZoom) * 0.1).clamp(_minZoom, _maxZoom);
    await _setZoom(newZoom);
  }

  Future<void> _classifyFromGallery() async {
    if (_isClassifying || !_isModelLoaded) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() => _isClassifying = true);
        
        final imageBytes = await pickedFile.readAsBytes();
        setState(() => _selectedImagePath = pickedFile.path);
        
        await _classifyImage(imageBytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gallery error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClassifying = false);
      }
    }
  }

  Future<void> _classifyImage(Uint8List imageBytes) async {
    try {
      final results = await _classifier.classifyImage(imageBytes);
      if (mounted) {
        setState(() {
          _results = results;
          if (results.isNotEmpty) {
            final topLabel = results.first.label;
            final topConfidence = results.first.confidence;
            
            if (!_classificationHistory.containsKey(topLabel)) {
              _classificationHistory[topLabel] = {
                'count': 0,
                'totalConfidence': 0.0,
                'results': [],
              };
            }
            
            final history = _classificationHistory[topLabel]!;
            history['count'] = (history['count'] as int) + 1;
            history['totalConfidence'] = (history['totalConfidence'] as double) + topConfidence;
            final resultsList = history['results'] as List;
            resultsList.add(topConfidence);

            _recentScans.insert(0, {
              'label': topLabel,
              'confidence': topConfidence,
              'timestamp': DateTime.now().toIso8601String(),
            });
            
            // Keep only last 100 scans
            if (_recentScans.length > 100) {
              _recentScans.removeLast();
            }
          }
        });
        await _saveClassificationHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Classification error: $e')),
        );
      }
    }
  }

  Future<void> _sendResultsToDatabase() async {
    if (_results.isEmpty) return;

    setState(() => _isSendingToDatabase = true);

    try {
      final topResult = _results.first;
      final timestamp = DateTime.now();
      
      final payload = {
        'classification': topResult.label,
        'confidence': topResult.confidence,
        'isValidClass': topResult.isValidClass,
        'validationMessage': topResult.validationMessage,
        'timestamp': timestamp,
        'timestampString': timestamp.toIso8601String(),
        'allResults': _results.map((r) => {
          'label': r.label,
          'confidence': r.confidence,
          'isValidClass': r.isValidClass,
          'validationMessage': r.validationMessage,
        }).toList(),
      };

      await FirebaseFirestore.instance
          .collection('classifications')
          .add(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classification sent to Firestore'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending to Firestore: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      developer.log('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSendingToDatabase = false);
      }
    }
  }

  @override
  void dispose() {
    _classifier.dispose();
    if (_isCameraInitialized) {
      _cameraController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: !_isModelLoaded
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          widget.selectedClassName != null
                              ? 'Classify\n${widget.selectedClassName}'
                              : 'Photo Editing Logo\nClassification',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 25,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 8,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: _selectedImagePath != null
                                ? Image.file(
                                    File(_selectedImagePath!),
                                    height: 280,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    height: 280,
                                    width: double.infinity,
                                    color: Colors.grey[100],
                                    child: Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        size: 80,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildMinimalButton(
                              icon: Icons.camera_alt_outlined,
                              label: 'Camera',
                              onPressed: _isClassifying ? null : _showCameraPreviewDialog,
                            ),
                            _buildMinimalButton(
                              icon: Icons.photo_library_outlined,
                              label: 'Gallery',
                              onPressed: _isClassifying ? null : _classifyFromGallery,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        if (_isClassifying)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (_results.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/images/meow.jpg'),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {
                                    developer.log('Background image not found: $exception');
                                  },
                                ),
                              ),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF013220),
                              ),
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Results',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ..._getDisplayResults().asMap().entries.map((entry) {
                                    final index = entry.key + 1;
                                    final result = entry.value;
                                    final percentage = (result.confidence * 100).toStringAsFixed(1);
                                    final isTopResult = index == 1;
                                    final description = _classDescriptions[result.label.toLowerCase()] ?? '';
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 16.0),
                                      child: Container(
                                        decoration: isTopResult
                                            ? BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.white70,
                                                  width: 2,
                                                ),
                                                borderRadius: BorderRadius.circular(4),
                                              )
                                            : null,
                                        padding: isTopResult ? const EdgeInsets.all(12.0) : null,
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: 24,
                                              child: Text(
                                                '$index',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white70,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            result.label.toUpperCase(),
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.w500,
                                                              letterSpacing: 1,
                                                              color: Colors.white,
                                                              fontStyle: isTopResult ? FontStyle.italic : FontStyle.normal,
                                                            ),
                                                          ),
                                                        ),
                                                        if (isTopResult)
                                                          Padding(
                                                            padding: const EdgeInsets.only(left: 8.0),
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                border: Border.all(color: Colors.white70, width: 1),
                                                                borderRadius: BorderRadius.circular(2),
                                                              ),
                                                              child: const Text(
                                                                'TOP',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.w600,
                                                                  letterSpacing: 1,
                                                                  color: Colors.white,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        if (!result.isValidClass)
                                                          Padding(
                                                            padding: const EdgeInsets.only(left: 8.0),
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                border: Border.all(color: Colors.redAccent, width: 1),
                                                                borderRadius: BorderRadius.circular(2),
                                                              ),
                                                              child: const Text(
                                                                'INVALID',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.w600,
                                                                  letterSpacing: 1,
                                                                  color: Colors.redAccent,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    if (description.isNotEmpty) ...[
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        description,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w300,
                                                          letterSpacing: 0.5,
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    ],
                                                    if (!result.isValidClass) ...[
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        '⚠️ ${result.validationMessage}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w400,
                                                          letterSpacing: 0.5,
                                                          color: Colors.redAccent,
                                                        ),
                                                      ),
                                                    ],
                                                    const SizedBox(height: 8),
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(1),
                                                      child: LinearProgressIndicator(
                                                        value: result.confidence,
                                                        minHeight: isTopResult ? 4 : 3,
                                                        backgroundColor: Colors.white30,
                                                        valueColor: AlwaysStoppedAnimation<Color>(
                                                          isTopResult ? Colors.white : Colors.white70,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 50,
                                              child: Text(
                                                '$percentage%',
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        if (_results.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _retakeClassification,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 1.5,
                                      ),
                                      color: Colors.white,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'RETAKE',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.5,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isSendingToDatabase ? null : _sendResultsToDatabase,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _isSendingToDatabase ? Colors.grey[400]! : Colors.black,
                                        width: 1.5,
                                      ),
                                      color: _isSendingToDatabase ? Colors.grey[100] : Colors.white,
                                    ),
                                    child: Center(
                                      child: _isSendingToDatabase
                                          ? Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      Colors.grey[600]!,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Sending...',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 1,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Text(
                                              'SEND TO DATABASE',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.5,
                                                color: Colors.black,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 20,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      'it\'s in the details. Always in the details.',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w300,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  top: 20,
                  child: GestureDetector(
                    onTap: () {
                      final navigator = Navigator.of(context);
                      _saveClassificationHistory().then((_) {
                        navigator.pop(_classificationHistory);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.5),
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '© 2025 Photo Editing Logo Classification',
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                if (_showCameraPreview)
                  Positioned.fill(
                    child: _buildCameraPreviewOverlay(),
                  ),
              ],
            ),
    );
  }

  Widget _buildCameraPreviewOverlay() {
    return Container(
      color: Colors.black,
      child: _isCameraInitialized
          ? Stack(
              alignment: Alignment.center,
              children: [
                if (_showPhotoConfirmation && _capturedImageBytes != null)
                  _buildPhotoConfirmationOverlay()
                else
                  _buildCameraViewStack(),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Widget _buildCameraViewStack() {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onScaleUpdate: (ScaleUpdateDetails details) {
              final newZoom = (_currentZoom * details.scale).clamp(_minZoom, _maxZoom);
              _setZoom(newZoom);
            },
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: 100,
                  height: 100 * _cameraController.value.aspectRatio,
                  child: Stack(
                    children: [
                      CameraPreview(_cameraController),
                      CustomPaint(
                        painter: GridPainter(),
                        size: Size.infinite,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _closeCameraPreview,
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                GestureDetector(
                  onTap: _toggleFlash,
                  child: Icon(
                    _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
                    color: _flashMode == FlashMode.off ? Colors.white : Colors.amber,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(_currentZoom).toStringAsFixed(1)}x',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 60),
                GestureDetector(
                  onTap: _isClassifying ? null : _capturePhoto,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _switchCamera,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.flip_camera_android,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoConfirmationOverlay() {
    return Stack(
      children: [
        Positioned.fill(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: 100,
                height: 100 * _cameraController.value.aspectRatio,
                child: Image.memory(
                  _capturedImageBytes!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: GestureDetector(
            onTap: _closeCameraPreview,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _retakePhoto,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.8),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _isClassifying ? null : _confirmAndClassifyPhoto,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withValues(alpha: 0.8),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: _isClassifying
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 32,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed != null ? 1.0 : 0.5,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: 32,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    final horizontalStep = size.height / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(0, horizontalStep * i),
        Offset(size.width, horizontalStep * i),
        paint,
      );
    }

    final verticalStep = size.width / 3;
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(verticalStep * i, 0),
        Offset(verticalStep * i, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}






