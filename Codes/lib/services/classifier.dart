import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'preprocessing_config.dart';

class ClassificationResult {
  final String label;
  final double confidence;
  final bool isValidClass;
  final String validationMessage;

  ClassificationResult({
    required this.label,
    required this.confidence,
    this.isValidClass = true,
    this.validationMessage = 'Valid class',
  });
}

class ImageClassifier {
  List<String> _labels = [];
  Interpreter? _interpreter;
  bool _isModelLoaded = false;
  static const int inputSize = 224;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model_unquant.tflite');
      await _loadLabels();
      
      if (_interpreter != null) {
        final inputTensor = _interpreter!.getInputTensor(0);
        final outputTensor = _interpreter!.getOutputTensor(0);
        developer.log('Input shape: ${inputTensor.shape}');
        developer.log('Output shape: ${outputTensor.shape}');
        developer.log('Labels count: ${_labels.length}');
      }
      
      _isModelLoaded = true;
    } catch (e) {
      throw Exception('Failed to load model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .map((label) {
            final parts = label.trim().split(' ');
            return parts.length > 1 ? parts.sublist(1).join(' ') : label.trim();
          })
          .toList();
      developer.log('Loaded ${_labels.length} labels: $_labels');
    } catch (e) {
      throw Exception('Failed to load labels: $e');
    }
  }

  Future<List<ClassificationResult>> classifyImage(Uint8List imageBytes) async {
    if (!_isModelLoaded || _interpreter == null) {
      throw Exception('Model not loaded');
    }

    try {
      developer.log('Starting classification');
      
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      developer.log('Image decoded: ${image.width}x${image.height}');

      final resizedImage = img.copyResize(image, width: inputSize, height: inputSize);
      developer.log('Image resized to ${inputSize}x$inputSize');
      
      final inputTensor = _interpreter!.getInputTensor(0);
      final outputTensor = _interpreter!.getOutputTensor(0);
      developer.log('Input: shape=${inputTensor.shape}, type=${inputTensor.type}');
      developer.log('Output: shape=${outputTensor.shape}, type=${outputTensor.type}');
      
      final input = _buildInputTensor(resizedImage);
      developer.log('Input tensor built');
      
      final outputShape = outputTensor.shape;
      final output = outputShape.length > 1
          ? List.generate(outputShape[0], (_) => List<double>.filled(outputShape[1], 0.0))
          : List<double>.filled(outputShape[0], 0.0);
      developer.log('Output buffer created with shape: $outputShape');
      
      developer.log('Running inference...');
      final config = PreprocessingConfig.getSettings();
      developer.log('Preprocessing mode: $config');
      _interpreter!.run(input, output);
      developer.log('Inference completed');
      
      var flatOutput = output is List<List<double>> ? List<double>.from(output[0]) : List<double>.from(output as List);
      // If model outputs are not already probabilities (sum ~= 1 and all in [0,1]),
      // convert logits/raw scores to probabilities using softmax.
      final within01 = flatOutput.every((v) => v >= 0.0 && v <= 1.0);
      final total = flatOutput.fold<double>(0.0, (p, e) => p + e);
      final isProbabilities = within01 && (total - 1.0).abs() < 0.1;
      if (!isProbabilities) {
        // apply softmax
        final maxVal = flatOutput.reduce((a, b) => a > b ? a : b);
        final List<double> exps = flatOutput.map<double>((v) => math.exp(v - maxVal)).toList();
        final double sumExps = exps.fold<double>(0.0, (p, e) => p + e);
        if (sumExps > 0) {
          flatOutput = exps.map((e) => e / sumExps).toList();
        }
      }
      developer.log('Raw output values: $flatOutput');
      
      int topIndex = 0;
      double topConfidence = 0.0;
      for (int i = 0; i < flatOutput.length; i++) {
        if (flatOutput[i] > topConfidence) {
          topConfidence = flatOutput[i];
          topIndex = i;
        }
      }
      
      final topLabel = _labels.isNotEmpty && topIndex < _labels.length ? _labels[topIndex] : 'unknown';
      developer.log('Top result: $topLabel (confidence: $topConfidence)');
      
      if (topIndex < 0 || topIndex >= _labels.length) {
        developer.log('⚠️  VALIDATION WARNING: Top result class index $topIndex is outside valid range [0, ${_labels.length - 1}]');
        developer.log('⚠️  This class does NOT belong to the model labels');
      }
      
      return _parseOutput(flatOutput);
    } catch (e, st) {
      developer.log('Classification error: $e\n$st');
      throw Exception('Classification failed: $e');
    }
  }

  dynamic _buildInputTensor(img.Image image) {
    final config = PreprocessingConfig.getSettings();
    
    return List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = image.getPixelSafe(x, y);
            
            double r = pixel.r.toDouble() / 255.0;
            double g = pixel.g.toDouble() / 255.0;
            double b = pixel.b.toDouble() / 255.0;
            
            if (config.normalize) {
              r = (r - config.mean[0]) / config.std[0];
              g = (g - config.mean[1]) / config.std[1];
              b = (b - config.mean[2]) / config.std[2];
            } else if (config.mean[0] != 0.0) {
              r = (r - config.mean[0]) / config.std[0];
              g = (g - config.mean[1]) / config.std[1];
              b = (b - config.mean[2]) / config.std[2];
            }
            
            if (config.useBGR) {
              return [b, g, r];
            } else {
              return [r, g, b];
            }
          },
        ),
      ),
    );
  }

  List<ClassificationResult> _parseOutput(List<double> confidences) {
    final results = <ClassificationResult>[];
    
    developer.log('Parsing output with ${confidences.length} confidence values');
    developer.log('Available labels: ${_labels.length}');
    
    final maxLen = confidences.length < _labels.length ? confidences.length : _labels.length;
    
    for (int i = 0; i < maxLen; i++) {
      try {
        final confidence = confidences[i];
        if (confidence.isFinite && confidence >= 0) {
          results.add(ClassificationResult(
            label: _labels[i],
            confidence: confidence.clamp(0.0, 1.0),
          ));
        }
      } catch (e) {
        developer.log('Error parsing output[$i]: $e');
        continue;
      }
    }

    developer.log('Parsed ${results.length} results');
    results.sort((a, b) => b.confidence.compareTo(a.confidence));
    return results;
  }

  void dispose() {
    _interpreter?.close();
  }
}
