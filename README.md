# 🎨 LogoScan – Photo Editing Logo Classification System

An intelligent image classification system powered by **Deep Learning and Convolutional Neural Networks (CNNs)** that accurately identifies photo editing application logos from images. LogoScan is designed for educational, research, and real-world mobile AI applications.

---

## 📋 Overview

**LogoScan** is a machine learning-powered mobile application that leverages computer vision and **TensorFlow Lite** to classify popular photo editing logos from camera captures or gallery uploads. This project demonstrates a complete **end-to-end ML pipeline** integrated into a **Flutter cross-platform application**, from data preprocessing and model training to mobile deployment and real-time inference.

---

## 📌 Project Scope

- **Type**: Supervised Learning – Image Classification  
- **Algorithm**: Convolutional Neural Networks (CNN)  
- **Platform**: Flutter (Android, iOS, Web, Desktop)  
- **Dataset**: Photo Editing App Logo Images  
- **Problem**: Multi-class classification  
- **Accuracy Target**: 90%+  
- **Deployment**: Mobile-optimized with TensorFlow Lite  

---

## 🎯 Project Objectives

- 📌 Accurately classify popular photo editing application logos  
- 📌 Implement a complete ML workflow in a mobile context  
- 📌 Apply deep learning to real-world logo recognition  
- 📌 Integrate real-time camera and gallery-based inference  
- 📌 Visualize confidence scores and analytics  
- 📌 Demonstrate practical ML + Flutter development skills  

---

## 🛠️ Technology Stack

| Component | Technology |
|---------|-----------|
| Mobile Framework | Flutter (Dart) |
| Deep Learning | TensorFlow / TensorFlow Lite |
| Model Type | CNN |
| Image Input | Camera, Gallery |
| Backend | Firebase (Firestore) |
| Visualization | FL Chart |
| Local Storage | SharedPreferences |
| IDE | VS Code / Android Studio |

---

## 📂 Project Structure

photo_editing_logo_classification/
│
├── android/
├── ios/
├── web/
├── windows/
├── macos/
├── linux/
│
├── assets/
│ ├── models/
│ │ ├── logo_model.tflite # Trained & quantized TFLite model
│ │ └── labels.txt # Logo class labels
│ │
│ └── images/
│ ├── adobe.jpg # Adobe Photoshop logo
│ ├── canva.jpg # Canva logo
│ ├── fotor.jpg # Fotor logo
│ ├── lr.jpg # Adobe Lightroom logo
│ ├── pics.jpg # PicsArt logo
│ ├── pix.jpg # Pixlr logo
│ ├── polar.jpg # Polarr logo
│ ├── remini.jpg # Remini logo
│ ├── snapseed.jpg # Snapseed logo
│ ├── vsco.jpg # VSCO logo
│ ├── anime.jpg # Sample test image
│ ├── meow.jpg # Placeholder image
│ ├── totoro.jpg # Sample test image
│ └── view.jpg # Sample test image
│
├── lib/
│ ├── main.dart # App entry point
│ ├── screens/
│ │ ├── home_screen.dart
│ │ ├── classification_screen.dart
│ │ ├── analytics_screen.dart
│ │ └── get_started_screen.dart
│ │
│ ├── services/
│ │ ├── classifier.dart # TFLite inference logic
│ │ ├── model_diagnostic.dart # Debug & diagnostics
│ │ └── preprocessing_config.dart
│ │
│ └── widgets/ # UI components
│
├── test/
│ └── widget_test.dart
│
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
└── .gitignore


---

## 📊 Dataset Information

| Logo Class | Samples |
|-----------|---------|
| Adobe Photoshop | 150 |
| Adobe Lightroom | 150 |
| Canva | 150 |
| PicsArt | 150 |
| Snapseed | 150 |
| VSCO | 150 |
| Fotor | 150 |
| Pixlr / Other | 150 |
| **Total** | **~1,200 images** |

- **Image Size**: 224×224  
- **Color Space**: RGB  
- **Split**: 60% Train • 20% Validation • 20% Test  

---

## 🧠 CNN Architecture



Input (224×224×3)
↓
Conv2D (32) + ReLU + BatchNorm
↓
MaxPooling
↓
Conv2D (64) + ReLU + BatchNorm
↓
MaxPooling
↓
Conv2D (128) + ReLU + BatchNorm
↓
MaxPooling
↓
Flatten
↓
Dense (256) + ReLU + Dropout(0.5)
↓
Dense (128) + ReLU + Dropout(0.3)
↓
Softmax Output (8 Classes)


---

## 📈 Performance Metrics

| Metric | Result |
|------|--------|
| Training Accuracy | 95% |
| Validation Accuracy | 93% |
| Testing Accuracy | 92% |
| Precision | 92% |
| Recall | 93% |
| F1-Score | 0.92 |
| Inference Time | ~250–400 ms |

---

## 📱 App Features

- 📷 Real-time camera logo classification  
- 🖼️ Gallery image selection  
- 📊 Confidence score visualization  
- 📈 Analytics dashboard  
- 💾 Local classification history  
- ☁️ Firebase Firestore integration  
- 🎨 Material Design 3 UI  

---

## 🎓 Educational Value

- Complete ML pipeline implementation  
- CNN training and evaluation  
- Mobile AI deployment using TensorFlow Lite  
- Flutter cross-platform development  
- Real-world logo recognition use case  

---

## 👤 Author

**Cyrel O. Rellin**  
BS Information Technology (BSIT)  
Caraga State University – Cabadbaran Campus  
Final Project • December 2025  

---

✨ *Thank you for exploring the LogoScan project!*  
🎨 *Classifying photo editing logos with AI, one image at a time.*
