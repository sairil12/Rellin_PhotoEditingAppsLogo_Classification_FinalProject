🎨 LogoScan – Photo Editing Logo Classification App

An intelligent image classification mobile application powered by Machine Learning and Computer Vision that identifies photo editing application logos from camera capture or gallery images. LogoScan is designed for educational, research, and mobile AI application development.

📋 Overview

LogoScan is a mobile-based image classification system that uses deep learning models to recognize and classify popular photo editing logos (e.g., Photoshop, Lightroom, Canva, PicsArt, etc.).
This project demonstrates a complete end-to-end AI workflow, integrated into a Flutter mobile application.

Project Scope

Type: Supervised Learning – Image Classification

Algorithm: CNN (Convolutional Neural Network)

Platform: Mobile (Flutter)

Dataset: Photo Editing App Logos

Problem: Multi-class classification

Deployment: Mobile-ready (Camera & Gallery Inference)

🎯 Project Objectives

📌 Classify photo editing logos from real-world images

📌 Integrate ML inference into a Flutter mobile app

📌 Support both camera capture and gallery upload

📌 Display classification confidence scores

📌 Analyze model performance visually

📌 Demonstrate practical AI & mobile development skills

🛠️ Technology Stack
Component	Technology
Mobile Framework	Flutter (Dart)
Machine Learning	TensorFlow / TensorFlow Lite
Model Type	CNN
Image Input	Camera, Image Picker
Image Processing	OpenCV / PIL
Backend (Optional)	Firebase / Local Inference
Visualization	Charts, Confidence Bars
IDE	VS Code / Android Studio
📂 Project Structure
PhotoEditingLogo_Classification_App/
│
├── android/                     # Android native files
├── ios/                         # iOS native files
├── web/                         # Web support (optional)
├── windows/                     # Windows desktop (optional)
├── macos/                       # macOS desktop (optional)
├── linux/                       # Linux desktop (optional)
│
├── assets/
│   ├── models/
│   │   ├── logo_model.tflite    # Trained TensorFlow Lite model
│   │   └── labels.txt           # Logo class labels
│   │
│   └── images/
│       ├── adobe.jpg            # Adobe Photoshop logo
│       ├── anime.jpg            # Anime-style sample image
│       ├── canva.jpg            # Canva logo
│       ├── fotor.jpg            # Fotor logo
│       ├── lr.jpg               # Adobe Lightroom logo
│       ├── meow.jpg             # Placeholder / test image
│       ├── pics.jpg             # PicsArt logo
│       ├── pix.jpg              # Pixlr logo
│       ├── polar.jpg            # Polarr logo
│       ├── remini.jpg           # Remini logo
│       ├── snapseed.jpg         # Snapseed logo
│       ├── totoro.jpg           # Sample image
│       ├── view.jpg             # Sample image
│       └── vsco.jpg             # VSCO logo
│
├── lib/
│   ├── main.dart                # App entry point
│
│   ├── screens/
│   │   ├── home_screen.dart     # Home / dashboard
│   │   ├── camera_screen.dart   # Camera capture
│   │   ├── gallery_screen.dart  # Gallery picker
│   │   ├── result_screen.dart   # Classification result
│   │   └── analytics_screen.dart# Charts & insights
│   │
│   ├── services/
│   │   ├── classifier.dart      # TFLite inference logic
│   │   ├── image_service.dart   # Camera & gallery handling
│   │   └── model_service.dart   # Model loading & initialization
│   │
│   ├── widgets/
│   │   ├── confidence_bar.dart  # Confidence visualization
│   │   ├── result_card.dart     # Prediction display card
│   │   ├── app_drawer.dart      # Burger menu / navigation drawer
│   │   └── custom_button.dart   # Reusable buttons
│   │
│   └── utils/
│       ├── constants.dart       # App constants
│       └── helpers.dart         # Utility functions
│
├── ml/
│   ├── training/
│   │   ├── 01_data_preparation.ipynb
│   │   ├── 02_model_training.ipynb
│   │   └── 03_evaluation.ipynb
│   │
│   └── exports/
│       ├── logo_model.h5        # Trained Keras model
│       └── logo_model.tflite    # Converted TensorFlow Lite model
│
├── results/
│   ├── confusion_matrix.png
│   ├── accuracy_curve.png
│   ├── loss_curve.png
│   └── sample_predictions.png
│
├── test/                        # Unit & widget tests
│
├── pubspec.yaml                 # Flutter dependencies & assets
├── analysis_options.yaml        # Lint rules
├── README.md                    # Project documentation
└── LICENSE

📊 Dataset Information
Logo Classes
Logo	Samples
Photoshop	150
Lightroom	150
Canva	150
PicsArt	150
Snapseed	150
VSCO	150
Others	150
Total	1,050 images
Dataset Properties

Image Size: 224 × 224

Color Space: RGB

Formats: PNG / JPG

Split Ratio:

Train: 70%

Validation: 15%

Test: 15%

Augmentation:

Rotation

Zoom

Brightness

Horizontal Flip

🧠 Model Architecture
INPUT IMAGE
↓
Conv2D + ReLU
↓
MaxPooling
↓
Conv2D + ReLU
↓
MaxPooling
↓
Conv2D + ReLU
↓
Flatten
↓
Dense + Dropout
↓
Softmax Output (Logo Classes)

Model Summary
Component	Details
Input Size	224×224×3
Conv Layers	3
Dense Layers	2
Output	Multi-class Softmax
Parameters	~2M
Optimization	Adam
Loss	Categorical Crossentropy
📈 Performance Metrics
Overall Accuracy
Metric	Result
Training Accuracy	95%
Validation Accuracy	93%
Test Accuracy	92%
Precision	92%
Recall	93%
F1-Score	0.92
Observations

✔ High accuracy on clean logo images

✔ Slight confusion between similar color logos

✔ Stable inference performance on mobile

📱 App Features

📷 Real-time camera classification

🖼️ Gallery image selection

📊 Confidence score visualization

📈 Analytics dashboard

🎨 Clean UI with modern layout

☰ Navigation drawer (Burger Menu)

🚧 Development Status

 Dataset preparation

 CNN model training

 Model evaluation

 Flutter UI integration

 Camera & gallery input

 Confidence visualization

 Transfer learning optimization

 Cloud-based inference

 App store deployment

🔮 Future Improvements
Short Term

 Add more logo classes

 Improve confidence calibration

 Enhance UI animations

Medium Term

 Web dashboard for analytics

 Firebase image storage

 API-based inference

Long Term

 Real-time video logo detection

 Explainable AI (Grad-CAM)

 Edge optimization for low-end devices

🎓 Educational Value

This project demonstrates:

✅ Practical mobile AI implementation

✅ CNN-based image classification

✅ Flutter + ML integration

✅ Dataset preparation and augmentation

✅ Performance analysis and visualization

✅ Real-world logo recognition problem

👤 Author

Cyrel O. Rellin

Program: BS Information Technology

Institution: Caraga State University Cabadbaran Campus

Project Type: Photo Editing Logo Classification (Final Project)

Year: 2025

⭐ Support

If you find this project helpful:

⭐ Star the repository

🔀 Fork and improve

💬 Share with classmates

🤝 Contribute ideas

Thank you for exploring the LogoScan project! 🎨📸
Recognizing photo editing tools through AI, one logo at a time.
