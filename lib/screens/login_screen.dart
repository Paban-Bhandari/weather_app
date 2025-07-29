import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Responsive helper methods
  bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }

  bool isLargeTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > 900;
  }

  double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return baseSize * 1.3; // Large tablet
    if (screenWidth > 600) return baseSize * 1.1; // Tablet
    return baseSize; // Phone
  }

  TextStyle getResponsiveTextStyle(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize ?? getResponsiveFontSize(context, 16),
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? Colors.white,
    ).copyWith(
      // Fallback to system font if Google Fonts fails
      fontFamilyFallback: ['Roboto', 'Arial', 'sans-serif'],
    );
  }

  double getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return 48.0; // Large tablet
    if (screenWidth > 600) return 32.0; // Tablet
    return 24.0; // Phone
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = this.isTablet(context);
    final isLargeTablet = this.isLargeTablet(context);
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo/Icon
                        Container(
                          width: isTablet ? 160 : 120,
                          height: isTablet ? 160 : 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: isTablet ? 3 : 2,
                            ),
                          ),
                          child: Lottie.asset(
                            'assets/sunny.json',
                            width: isTablet ? 100 : 80,
                            height: isTablet ? 100 : 80,
                            fit: BoxFit.contain,
                            repeat: true,
                          ),
                        ),

                        SizedBox(height: isTablet ? 60 : 40),

                        // App Title
                        Text(
                          'Weather Pro',
                          style: getResponsiveTextStyle(
                            context,
                            fontSize: getResponsiveFontSize(context, 36),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ).copyWith(letterSpacing: 1.2),
                        ),

                        SizedBox(height: isTablet ? 12 : 8),

                        // Subtitle
                        Text(
                          'Your Personal Weather Companion',
                          style: getResponsiveTextStyle(
                            context,
                            fontSize: getResponsiveFontSize(context, 16),
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: isTablet ? 80 : 60),

                        // Features
                        _buildFeature(
                          context,
                          Icons.cloud,
                          'Real-time weather data',
                        ),
                        _buildFeature(
                          context,
                          Icons.location_on,
                          'Location-based forecasts',
                        ),
                        _buildFeature(
                          context,
                          Icons.favorite,
                          'Save your favorite cities',
                        ),
                        _buildFeature(
                          context,
                          Icons.analytics,
                          'Detailed weather analytics',
                        ),

                        SizedBox(height: isTablet ? 80 : 60),

                        // Sign-in Options
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return Column(
                              children: [
                                if (authProvider.isLoading)
                                  CircularProgressIndicator(
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                    strokeWidth: isTablet ? 4 : 3,
                                  )
                                else ...[
                                  // Web: Show email/password option
                                  if (kIsWeb) ...[
                                    _buildWebSignInInfo(context),
                                    SizedBox(height: isTablet ? 20 : 16),
                                  ],

                                  _buildGoogleSignInButton(
                                    context,
                                    authProvider,
                                  ),
                                ],

                                if (authProvider.error != null) ...[
                                  SizedBox(height: isTablet ? 20 : 16),
                                  Container(
                                    padding: EdgeInsets.all(isTablet ? 16 : 12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(
                                        isTablet ? 12 : 8,
                                      ),
                                      border: Border.all(
                                        color: Colors.red.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      authProvider.error!,
                                      style: getResponsiveTextStyle(
                                        context,
                                        fontSize: getResponsiveFontSize(
                                          context,
                                          14,
                                        ),
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(BuildContext context, IconData icon, String text) {
    final isTablet = this.isTablet(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 8 : 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: isTablet ? 20 : 16),
                SizedBox(width: isTablet ? 8 : 6),
                Flexible(
                  child: Text(
                    text,
                    style: getResponsiveTextStyle(
                      context,
                      fontSize: getResponsiveFontSize(context, 14),
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSignInInfo(BuildContext context) {
    final isTablet = this.isTablet(context);

    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange,
            size: isTablet ? 24 : 20,
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            'Web Sign-in Note',
            style: getResponsiveTextStyle(
              context,
              fontSize: getResponsiveFontSize(context, 14),
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          SizedBox(height: isTablet ? 4 : 2),
          Text(
            'Google Sign-in requires proper web configuration. For now, please use the mobile app for full functionality.',
            style: getResponsiveTextStyle(
              context,
              fontSize: getResponsiveFontSize(context, 12),
              color: Colors.white.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    final isTablet = this.isTablet(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive width to prevent overflow
    final buttonWidth = isTablet
        ? (screenWidth * 0.5).clamp(
            250.0,
            320.0,
          ) // Tablet: 50% of screen width, max 320px
        : (screenWidth * 0.7).clamp(
            180.0,
            250.0,
          ); // Phone: 70% of screen width, max 250px

    return Container(
      width: buttonWidth,
      height: isTablet ? 60 : 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isTablet ? 30 : 25),
          onTap: () => authProvider.signInWithGoogle(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Custom Google logo
              Container(
                width: isTablet ? 32 : 24,
                height: isTablet ? 32 : 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: const Color(0xFF4285F4), // Google blue
                      fontSize: isTablet ? 18 : 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Flexible(
                child: Text(
                  'Sign in with Google',
                  style: getResponsiveTextStyle(
                    context,
                    fontSize: getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF667eea),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
