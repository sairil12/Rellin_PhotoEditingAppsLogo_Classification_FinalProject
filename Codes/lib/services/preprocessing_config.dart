enum PreprocessingMode {
  mode1,
  mode2,
  mode3,
  mode4,
  mode5,
}

class PreprocessingConfig {
  static const PreprocessingMode activeMode = PreprocessingMode.mode3;
  
  static const Map<PreprocessingMode, PreprocessingSettings> modes = {
    PreprocessingMode.mode1: PreprocessingSettings(
      name: 'RGB 0-1 (Default)',
      useBGR: false,
      normalize: false,
      mean: [0.0, 0.0, 0.0],
      std: [1.0, 1.0, 1.0],
    ),
    PreprocessingMode.mode2: PreprocessingSettings(
      name: 'BGR 0-1',
      useBGR: true,
      normalize: false,
      mean: [0.0, 0.0, 0.0],
      std: [1.0, 1.0, 1.0],
    ),
    PreprocessingMode.mode3: PreprocessingSettings(
      name: 'RGB ImageNet Norm',
      useBGR: false,
      normalize: true,
      mean: [0.485, 0.456, 0.406],
      std: [0.229, 0.224, 0.225],
    ),
    PreprocessingMode.mode4: PreprocessingSettings(
      name: 'BGR ImageNet Norm',
      useBGR: true,
      normalize: true,
      mean: [0.485, 0.456, 0.406],
      std: [0.229, 0.224, 0.225],
    ),
    PreprocessingMode.mode5: PreprocessingSettings(
      name: 'RGB -1 to 1',
      useBGR: false,
      normalize: false,
      mean: [0.5, 0.5, 0.5],
      std: [0.5, 0.5, 0.5],
    ),
  };
  
  static PreprocessingSettings getSettings() {
    return modes[activeMode]!;
  }
}

class PreprocessingSettings {
  final String name;
  final bool useBGR;
  final bool normalize;
  final List<double> mean;
  final List<double> std;
  
  const PreprocessingSettings({
    required this.name,
    required this.useBGR,
    required this.normalize,
    required this.mean,
    required this.std,
  });
  
  @override
  String toString() => name;
}
