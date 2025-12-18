import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:typed_data';

class ModelDiagnostic {
  static Future<void> analyzeModel(String modelPath) async {
    try {
      final interpreter = await Interpreter.fromAsset(modelPath);
      
      developer.log('=== MODEL DIAGNOSTIC ===');
      developer.log('Model: $modelPath');
      
      final inputTensor = interpreter.getInputTensor(0);
      final outputTensor = interpreter.getOutputTensor(0);
      
      developer.log('INPUT TENSOR:');
      developer.log('  Shape: ${inputTensor.shape}');
      developer.log('  Type: ${inputTensor.type}');
      developer.log('  Quantization: ${inputTensor.quantizationParameters}');
      
      developer.log('OUTPUT TENSOR:');
      developer.log('  Shape: ${outputTensor.shape}');
      developer.log('  Type: ${outputTensor.type}');
      developer.log('  Quantization: ${outputTensor.quantizationParameters}');
      
      developer.log('=== EXPECTED PREPROCESSING ===');
      developer.log('Input shape suggests: Batch=${inputTensor.shape[0]}, Height=${inputTensor.shape[1]}, Width=${inputTensor.shape[2]}, Channels=${inputTensor.shape[3]}');
      developer.log('Output shape suggests: ${outputTensor.shape[0]} classes');
      
      if (outputTensor.type.toString().contains('int')) {
        developer.log('⚠️  OUTPUT IS QUANTIZED - May need dequantization!');
      }
      
      developer.log('=== TEST WITH SAMPLE INPUT ===');
      await _validateModelWithSampleInput(interpreter, inputTensor, outputTensor);
      
      developer.log('=== TROUBLESHOOTING ===');
      developer.log('1. Check if preprocessing matches training:');
      developer.log('   - Image normalization (0-1 or -1 to 1 or mean/std?)');
      developer.log('   - Color order (RGB vs BGR)');
      developer.log('   - Image resizing method (aspect ratio preserved or stretched?)');
      developer.log('2. Enable different preprocessing flags in classifier.dart');
      developer.log('3. Check raw output values in logcat');
      
      interpreter.close();
    } catch (e) {
      developer.log('Diagnostic error: $e');
    }
  }

  static Future<void> _validateModelWithSampleInput(
    Interpreter interpreter,
    TensorFlite inputTensor,
    TensorFlite outputTensor,
  ) async {
    try {
      final inputShape = inputTensor.shape;
      final outputShape = outputTensor.shape;
      final numClasses = outputShape.length > 1 ? outputShape[1] : outputShape[0];

      final sampleInput = _generateRandomInput(inputShape);
      final output = outputShape.length > 1
          ? List.generate(outputShape[0], (_) => List<double>.filled(outputShape[1], 0.0))
          : List<double>.filled(outputShape[0], 0.0);

      interpreter.run(sampleInput, output);

      var flatOutput = output is List<List<double>>
          ? List<double>.from(output[0])
          : List<double>.from(output as List);

      developer.log('Sample inference output (first 10 values): ${flatOutput.take(10).toList()}');
      developer.log('Output length: ${flatOutput.length}');
      developer.log('Expected classes: $numClasses');

      if (flatOutput.length != numClasses) {
        developer.log('⚠️  MISMATCH: Output has ${flatOutput.length} values but expected $numClasses classes!');
      }

      final within01 = flatOutput.every((v) => v >= 0.0 && v <= 1.0);
      final total = flatOutput.fold<double>(0.0, (p, e) => p + e);
      final isProbabilities = within01 && (total - 1.0).abs() < 0.1;

      if (!isProbabilities) {
        developer.log('⚠️  Output is NOT normalized probabilities. Applying softmax...');
        final maxVal = flatOutput.reduce((a, b) => a > b ? a : b);
        final exps = flatOutput.map<double>((v) => math.exp(v - maxVal)).toList();
        final sumExps = exps.fold<double>(0.0, (p, e) => p + e);
        if (sumExps > 0) {
          flatOutput = exps.map((e) => e / sumExps).toList();
        }
        developer.log('After softmax: ${flatOutput.take(10).toList()}');
      } else {
        developer.log('✓ Output is valid probabilities');
      }

      int topIndex = 0;
      double topConfidence = 0.0;
      for (int i = 0; i < flatOutput.length; i++) {
        if (flatOutput[i] > topConfidence) {
          topConfidence = flatOutput[i];
          topIndex = i;
        }
      }

      developer.log('Top prediction: Class $topIndex with confidence $topConfidence');

      if (topIndex >= 0 && topIndex < numClasses) {
        developer.log('✓ Predicted class index is valid (within 0-${numClasses - 1})');
      } else {
        developer.log('✗ INVALID CLASS INDEX: $topIndex is outside valid range [0, ${numClasses - 1}]');
      }
    } catch (e) {
      developer.log('Error validating model with sample input: $e');
    }
  }

  static dynamic _generateRandomInput(List<int> inputShape) {
    final random = math.Random();
    
    if (inputShape.length == 4) {
      final batch = inputShape[0];
      final height = inputShape[1];
      final width = inputShape[2];
      final channels = inputShape[3];

      return List.generate(
        batch,
        (_) => List.generate(
          height,
          (y) => List.generate(
            width,
            (x) => List.generate(
              channels,
              (_) => random.nextDouble(),
            ),
          ),
        ),
      );
    } else {
      return List.generate(inputShape[0], (_) => random.nextDouble());
    }
  }
}
