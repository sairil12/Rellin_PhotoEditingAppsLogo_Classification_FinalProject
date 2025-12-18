import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'dart:ui';
import 'classification_screen.dart';
import 'get_started_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, Map<String, dynamic>> _classificationHistory = {};

  static const List<Map<String, dynamic>> _appClasses = [
    {
      'name': 'Adobe Photos',
      'image': 'assets/images/adobe.jpg',
      'description': 'Professional photo editing and creative tools',
    },
    {
      'name': 'Canva',
      'image': 'assets/images/canva.jpg',
      'description': 'Design and create stunning graphics easily',
    },
    {
      'name': 'Fotor',
      'image': 'assets/images/fotor.jpg',
      'description': 'Quick and easy photo editing software',
    },
    {
      'name': 'Lightroom',
      'image': 'assets/images/lr.jpg',
      'description': 'Advanced photo organization and editing',
    },
    {
      'name': 'PicsArt',
      'image': 'assets/images/pics.jpg',
      'description': 'Powerful photo and video editing app',
    },
    {
      'name': 'Pixlr',
      'image': 'assets/images/pix.jpg',
      'description': 'Intuitive online and offline photo editor',
    },
    {
      'name': 'Polarr',
      'image': 'assets/images/polar.jpg',
      'description': 'Advanced editing with AI-powered filters',
    },
    {
      'name': 'Remini',
      'image': 'assets/images/remini.jpg',
      'description': 'AI photo enhancement and restoration',
    },
    {
      'name': 'Snapseed',
      'image': 'assets/images/snapseed.jpg',
      'description': 'Feature-rich Google photo editor',
    },
    {
      'name': 'VSCO',
      'image': 'assets/images/vsco.jpg',
      'description': 'Photography community and editing platform',
    },
  ];

  static const List<Color> _cardColors = [
    Color(0xFF1F77B4),
    Color(0xFFE377C2),
    Color(0xFFFF7F0E),
    Color(0xFF17BECF),
    Color(0xFF9467BD),
    Color(0xFF8C564B),
    Color(0xFF7F7F7F),
    Color(0xFFD62728),
    Color(0xFF2CA02C),
    Color(0xFFBCBD22),
    
  ];

  @override
  void initState() {
    super.initState();
    _loadClassificationHistory();
  }

  Future<void> _loadClassificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('classification_history');
    
    if (historyJson != null) {
      try {
        final decoded = jsonDecode(historyJson) as Map<String, dynamic>;
        setState(() {
          _classificationHistory = decoded.map((key, value) {
            final map = value as Map<String, dynamic>;
            return MapEntry(key, {
              'count': map['count'] as int,
              'totalConfidence': map['totalConfidence'] as double,
              'results': List<double>.from(map['results'] as List),
            });
          });
        });
      } catch (e) {
        _classificationHistory = {};
      }
    }
  }

  Future<void> _saveClassificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(_classificationHistory);
    await prefs.setString('classification_history', historyJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const GetStartedScreen()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: _showAnalyticsBottomSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/meow.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Photo Editing Logo\nClassification',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 3.5,
                      height: 1.4,
                      color: Colors.white,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Identify photo editing apps by their logos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 2.2,
                      color: const Color.fromARGB(255, 5, 5, 5),
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Supported Apps',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                      fontSize: 16,
                      color: const Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _appClasses.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildAppCard(index),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 20,
            right: 0,
            child: Center(
              child: Text(
                '© 2025 Photo Editing Logo Classification',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w300,
                  color: Colors.black,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showAnalyticsBottomSheet() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
    );
  }



  Widget _buildAppCard(int index) {
    final app = _appClasses[index];
    final color = _cardColors[index];

    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClassificationScreen(selectedClassName: app['name']),
          ),
        );
        
        await _loadClassificationHistory();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.5),
          color: color.withValues(alpha: 0.08),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: app.containsKey('image') && app['image'] != null
                    ? app['image']!.endsWith('.svg')
                        ? SvgPicture.asset(
                            app['image']!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                          )
                        : ClipOval(
                            child: Image.asset(
                              app['image']!,
                              fit: BoxFit.cover,
                              width: 60,
                              height: 60,
                            ),
                          )
                    : Text(
                        app['emoji']!,
                        style: const TextStyle(fontSize: 44),
                      ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    app['name']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    app['description']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                      color: const Color.fromARGB(255, 245, 244, 244),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
