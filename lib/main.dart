import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'services/firestore_service.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if Firebase is already initialized to prevent duplicate app error
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Weather Pro',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<firebase_auth.User?>(
      stream: firebase_auth.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const WeatherHomePage();
        }

        return const LoginScreen();
      },
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage>
    with TickerProviderStateMixin {
  final String apiKey = 'f5ccb4363e4bf262751f92ea1f726e23';
  final TextEditingController _controller = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, dynamic>? weatherData;
  Map<String, dynamic>? forecastData;
  String? error;
  bool loading = false;
  bool forecastLoading = false;
  int currentIndex = 0;
  late AnimationController _animationController;
  late AnimationController _forecastAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _forecastFadeAnimation;

  // Responsive helper methods
  bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return baseSize * 1.3; // Large tablet
    if (screenWidth > 600) return baseSize * 1.1; // Tablet
    return baseSize; // Phone
  }

  double getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return 32.0; // Large tablet
    if (screenWidth > 600) return 24.0; // Tablet
    return 20.0; // Phone
  }

  int getGridCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return 4; // Large tablet
    if (screenWidth > 600) return 3; // Tablet
    return 2; // Phone
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _forecastAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _forecastFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _forecastAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    fetchWeather('Kathmandu');
  }

  Future<void> fetchWeather(String city) async {
    setState(() {
      loading = true;
      error = null;
    });

    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final weatherDataResponse = json.decode(response.body);
        setState(() {
          weatherData = weatherDataResponse;
          loading = false;
        });

        // Save to Firestore if user is authenticated
        await _firestoreService.saveWeatherSearch(
          city: city,
          weatherData: weatherDataResponse,
        );

        _animationController.forward();
        fetchForecast(city);
      } else {
        setState(() {
          error = 'City not found. Please try again.';
          weatherData = null;
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Network error. Please check your connection.';
        weatherData = null;
        loading = false;
      });
    }
  }

  Future<void> fetchForecast(String city) async {
    setState(() {
      forecastLoading = true;
    });

    final url =
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          forecastData = json.decode(response.body);
          forecastLoading = false;
        });
        _forecastAnimationController.forward();
      } else {
        setState(() {
          forecastData = null;
          forecastLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        forecastData = null;
        forecastLoading = false;
      });
    }
  }

  String getWeatherAnimation(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear':
        return 'assets/sunny.json';
      case 'clouds':
        return 'assets/cloudy.json';
      case 'rain':
      case 'drizzle':
        return 'assets/rainy.json';
      case 'snow':
        return 'assets/snowy.json';
      case 'partially cloudy':
        return 'assets/partially_cloudy.json';
      default:
        return 'assets/sunny.json';
    }
  }

  Color getWeatherColor(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'clear':
        return const Color(0xFFFFD700);
      case 'clouds':
        return const Color(0xFF87CEEB);
      case 'rain':
      case 'drizzle':
        return const Color(0xFF4682B4);
      case 'snow':
        return const Color(0xFFF0F8FF);
      default:
        return const Color(0xFF87CEEB);
    }
  }

  Widget buildShimmerLoading() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = this.isTablet(context);
        final padding = getResponsivePadding(context);

        return Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.white.withValues(alpha: 0.3),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: padding),
                padding: EdgeInsets.all(isTablet ? 32 : 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isTablet ? 32 : 24),
                ),
                child: Column(
                  children: [
                    Container(
                      width: isTablet ? 300 : 200,
                      height: isTablet ? 24 : 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    SizedBox(height: isTablet ? 24 : 20),
                    Container(
                      width: isTablet ? 160 : 120,
                      height: isTablet ? 160 : 120,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isTablet ? 24 : 20),
                    Container(
                      width: isTablet ? 140 : 100,
                      height: isTablet ? 48 : 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    SizedBox(height: isTablet ? 12 : 10),
                    Container(
                      width: isTablet ? 200 : 150,
                      height: isTablet ? 24 : 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildWeatherCard() {
    if (loading) {
      return buildShimmerLoading();
    }

    if (error != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = this.isTablet(context);
          final padding = getResponsivePadding(context);

          return Center(
            child: Container(
              margin: EdgeInsets.all(padding),
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: isTablet ? 64 : 48,
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: getResponsiveFontSize(context, 16),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_controller.text.trim().isNotEmpty) {
                        fetchWeather(_controller.text.trim());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF667eea),
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : 24,
                        vertical: isTablet ? 16 : 12,
                      ),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: getResponsiveFontSize(context, 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (weatherData == null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Text(
              'No weather data available',
              style: TextStyle(
                color: Colors.white,
                fontSize: getResponsiveFontSize(context, 16),
              ),
            ),
          );
        },
      );
    }

    final city = weatherData!['name'];
    final country = weatherData!['sys']['country'];
    final temp = weatherData!['main']['temp'].round();
    final feelsLike = weatherData!['main']['feels_like'].round();
    final desc = weatherData!['weather'][0]['description'];
    final weatherMain = weatherData!['weather'][0]['main'].toString();
    final humidity = weatherData!['main']['humidity'];
    final windSpeed = weatherData!['wind']['speed'];
    final pressure = weatherData!['main']['pressure'];
    final visibility = weatherData!['visibility'] / 1000; // Convert to km
    final sunrise = DateTime.fromMillisecondsSinceEpoch(
      weatherData!['sys']['sunrise'] * 1000,
    );
    final sunset = DateTime.fromMillisecondsSinceEpoch(
      weatherData!['sys']['sunset'] * 1000,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = this.isTablet(context);

        final padding = getResponsivePadding(context);

        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Main Weather Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: padding),
                    padding: EdgeInsets.all(isTablet ? 32 : 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(isTablet ? 32 : 24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: isTablet ? 30 : 20,
                          offset: Offset(0, isTablet ? 15 : 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Location with time and favorite button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.white,
                                    size: isTablet ? 28 : 20,
                                  ),
                                  SizedBox(width: isTablet ? 12 : 8),
                                  Expanded(
                                    child: Text(
                                      '$city, $country',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: getResponsiveFontSize(
                                          context,
                                          24,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Favorite button
                            FutureBuilder<bool>(
                              future: _firestoreService.isFavoriteCity(city),
                              builder: (context, snapshot) {
                                final isFavorite = snapshot.data ?? false;
                                return IconButton(
                                  onPressed: () async {
                                    if (isFavorite) {
                                      await _firestoreService
                                          .removeFavoriteCity(city);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '$city removed from favorites',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      await _firestoreService.saveFavoriteCity(
                                        city: city,
                                        country: country,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '$city added to favorites',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                    setState(() {}); // Rebuild to update icon
                                  },
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite
                                        ? Colors.red
                                        : Colors.white.withOpacity(0.8),
                                    size: isTablet ? 32 : 24,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Text(
                          DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: getResponsiveFontSize(context, 14),
                          ),
                        ),
                        SizedBox(height: isTablet ? 32 : 24),

                        // Weather Animation
                        Container(
                          width: isTablet ? 160 : 120,
                          height: isTablet ? 160 : 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: getWeatherColor(
                              weatherMain,
                            ).withOpacity(0.2),
                          ),
                          child: Lottie.asset(
                            getWeatherAnimation(weatherMain),
                            width: isTablet ? 100 : 80,
                            height: isTablet ? 100 : 80,
                            fit: BoxFit.contain,
                            repeat: true,
                          ),
                        ),
                        SizedBox(height: isTablet ? 32 : 24),

                        // Temperature
                        Text(
                          '$temp°C',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: getResponsiveFontSize(context, 64),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Weather Description
                        Text(
                          desc[0].toUpperCase() + desc.substring(1),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: getResponsiveFontSize(context, 18),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // Feels Like
                        Text(
                          'Feels like $feelsLike°C',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: getResponsiveFontSize(context, 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isTablet ? 24 : 20),

                  // Weather Details Grid
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: padding),
                    padding: EdgeInsets.all(isTablet ? 28 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Weather Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: getResponsiveFontSize(context, 20),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: isTablet ? 24 : 20),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: getGridCrossAxisCount(context),
                          crossAxisSpacing: isTablet ? 20 : 16,
                          mainAxisSpacing: isTablet ? 20 : 16,
                          childAspectRatio: isTablet ? 1.8 : 1.5,
                          children: [
                            _buildDetailCard(
                              context,
                              'Humidity',
                              '$humidity%',
                              Icons.water_drop,
                            ),
                            _buildDetailCard(
                              context,
                              'Wind Speed',
                              '${windSpeed.toStringAsFixed(1)} m/s',
                              Icons.air,
                            ),
                            _buildDetailCard(
                              context,
                              'Pressure',
                              '${pressure} hPa',
                              Icons.compress,
                            ),
                            _buildDetailCard(
                              context,
                              'Visibility',
                              '${visibility.toStringAsFixed(1)} km',
                              Icons.visibility,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isTablet ? 24 : 20),

                  // Sunrise/Sunset Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: padding),
                    padding: EdgeInsets.all(isTablet ? 28 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Sun Schedule',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: getResponsiveFontSize(context, 20),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: isTablet ? 20 : 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSunInfo(
                              context,
                              'Sunrise',
                              DateFormat('HH:mm').format(sunrise),
                              Icons.wb_sunny,
                              Colors.orange,
                            ),
                            _buildSunInfo(
                              context,
                              'Sunset',
                              DateFormat('HH:mm').format(sunset),
                              Icons.nightlight_round,
                              Colors.deepPurple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isTablet ? 24 : 20),

                  // Forecast Section
                  if (forecastData != null) buildForecastSection(context),

                  SizedBox(height: isTablet ? 48 : 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildForecastSection(BuildContext context) {
    final isTablet = this.isTablet(context);
    final padding = getResponsivePadding(context);

    if (forecastLoading) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: padding),
        padding: EdgeInsets.all(isTablet ? 28 : 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.3),
          child: Column(
            children: [
              Container(
                width: isTablet ? 200 : 150,
                height: isTablet ? 24 : 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: isTablet ? 24 : 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  5,
                  (index) => Container(
                    width: isTablet ? 80 : 60,
                    height: isTablet ? 100 : 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final List<dynamic> forecastList = forecastData!['list'];
    final List<Map<String, dynamic>> dailyForecasts = [];

    // Group forecasts by day
    Map<String, List<Map<String, dynamic>>> groupedForecasts = {};

    for (var forecast in forecastList) {
      final date = DateTime.parse(forecast['dt_txt']);
      final day = DateFormat('yyyy-MM-dd').format(date);

      if (!groupedForecasts.containsKey(day)) {
        groupedForecasts[day] = [];
      }
      groupedForecasts[day]!.add(forecast);
    }

    // Get daily averages for next 5 days
    final today = DateTime.now();
    final sortedDays = groupedForecasts.keys.toList()..sort();

    for (String day in sortedDays) {
      if (dailyForecasts.length < 5) {
        final dayDate = DateTime.parse(day);

        // Only include future days (skip today if it's already late)
        if (dayDate.isAfter(today) ||
            (dayDate.day == today.day &&
                dayDate.month == today.month &&
                dayDate.year == today.year)) {
          final forecasts = groupedForecasts[day]!;
          final avgTemp =
              forecasts.map((f) => f['main']['temp']).reduce((a, b) => a + b) /
              forecasts.length;

          // Get the most common weather condition for the day
          final weatherCounts = <String, int>{};
          for (var forecast in forecasts) {
            final weather = forecast['weather'][0]['main'];
            weatherCounts[weather] = (weatherCounts[weather] ?? 0) + 1;
          }
          final mostCommonWeather = weatherCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;

          // Find the forecast with the most common weather
          final representativeForecast = forecasts.firstWhere(
            (f) => f['weather'][0]['main'] == mostCommonWeather,
            orElse: () => forecasts.first,
          );

          dailyForecasts.add({
            'date': dayDate,
            'temp': avgTemp.round(),
            'weather': representativeForecast['weather'][0],
          });
        }
      }
    }

    return FadeTransition(
      opacity: _forecastFadeAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: padding),
        padding: EdgeInsets.all(isTablet ? 28 : 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: getResponsiveFontSize(context, 20),
                ),
                SizedBox(width: 8),
                Text(
                  'Next 5 Days Forecast',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 24 : 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: dailyForecasts.map((forecast) {
                final date = forecast['date'] as DateTime;
                final temp = forecast['temp'] as int;
                final weather = forecast['weather'] as Map<String, dynamic>;

                return Column(
                  children: [
                    Text(
                      DateFormat('E').format(date),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: getResponsiveFontSize(context, 14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d').format(date),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: getResponsiveFontSize(context, 12),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: isTablet ? 12 : 8),
                    Container(
                      width: isTablet ? 50 : 40,
                      height: isTablet ? 50 : 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: getWeatherColor(
                          weather['main'],
                        ).withOpacity(0.2),
                      ),
                      child: Lottie.asset(
                        getWeatherAnimation(weather['main']),
                        width: isTablet ? 35 : 30,
                        height: isTablet ? 35 : 30,
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    ),
                    SizedBox(height: isTablet ? 12 : 8),
                    Text(
                      '$temp°C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: getResponsiveFontSize(context, 16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Forecast',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: getResponsiveFontSize(context, 10),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final isTablet = this.isTablet(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: isTablet ? 32 : 24),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 6 : 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: getResponsiveFontSize(context, 12),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSunInfo(
    BuildContext context,
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    final isTablet = this.isTablet(context);

    return Column(
      children: [
        Icon(icon, color: color, size: isTablet ? 32 : 24),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          time,
          style: TextStyle(
            color: Colors.white,
            fontSize: getResponsiveFontSize(context, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: getResponsiveFontSize(context, 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = this.isTablet(context);
    final padding = getResponsivePadding(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(padding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weather Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: getResponsiveFontSize(context, 32),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: isTablet ? 12 : 8),
                          Text(
                            'Get accurate weather information',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: getResponsiveFontSize(context, 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Profile Button
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      icon: Container(
                        padding: EdgeInsets.all(isTablet ? 12 : 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(
                            isTablet ? 16 : 12,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: isTablet ? 32 : 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: isTablet ? 20 : 16),
                      Icon(
                        Icons.search,
                        color: Colors.white,
                        size: isTablet ? 28 : 24,
                      ),
                      SizedBox(width: isTablet ? 16 : 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: getResponsiveFontSize(context, 16),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search for a city...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: getResponsiveFontSize(context, 16),
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              fetchWeather(value.trim());
                              _controller.clear();
                            }
                          },
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(isTablet ? 12 : 8),
                        child: ElevatedButton(
                          onPressed: () {
                            final city = _controller.text.trim();
                            if (city.isNotEmpty) {
                              fetchWeather(city);
                              _controller.clear();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF667eea),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                isTablet ? 25 : 20,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 28 : 20,
                              vertical: isTablet ? 16 : 12,
                            ),
                          ),
                          child: Text(
                            'Search',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: getResponsiveFontSize(context, 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: isTablet ? 24 : 20),

              // Weather Content
              Expanded(child: buildWeatherCard()),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    _forecastAnimationController.dispose();
    super.dispose();
  }
}
