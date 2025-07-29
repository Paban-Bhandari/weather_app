import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> favoriteCities = [];
  List<Map<String, dynamic>> searchHistory = [];
  bool isLoading = true;

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

  double getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 900) return 32.0; // Large tablet
    if (screenWidth > 600) return 24.0; // Tablet
    return 20.0; // Phone
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load data using streams
      _firestoreService.getFavoriteCities().listen((snapshot) {
        final favorites = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        setState(() {
          favoriteCities = favorites;
        });
      });

      _firestoreService.getWeatherHistory().listen((snapshot) {
        final history = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
        setState(() {
          searchHistory = history;
          isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.all(padding),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: isTablet ? 32 : 24,
                          ),
                        ),
                        SizedBox(width: isTablet ? 16 : 12),
                        Text(
                          'Profile',
                          style: GoogleFonts.poppins(
                            fontSize: getResponsiveFontSize(context, 28),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return IconButton(
                              onPressed: () async {
                                await authProvider.signOut();
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              icon: Icon(
                                Icons.logout,
                                color: Colors.white,
                                size: isTablet ? 32 : 24,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(child: _buildContent()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final isTablet = this.isTablet(context);
    final padding = getResponsivePadding(context);

    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: isTablet ? 4 : 3,
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Card
          _buildUserInfoCard(),
          SizedBox(height: isTablet ? 32 : 24),

          // Favorite Cities Section
          _buildSectionTitle('Favorite Cities'),
          SizedBox(height: isTablet ? 16 : 12),
          _buildFavoriteCitiesList(),
          SizedBox(height: isTablet ? 32 : 24),

          // Search History Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Recent Searches'),
                  if (searchHistory.isNotEmpty)
                    Text(
                      '${searchHistory.length} items',
                      style: GoogleFonts.poppins(
                        fontSize: getResponsiveFontSize(context, 12),
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
              if (searchHistory.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton.icon(
                    onPressed: () => _showClearHistoryDialog(context),
                    icon: Icon(
                      Icons.clear_all,
                      color: Colors.red,
                      size: isTablet ? 20 : 16,
                    ),
                    label: Text(
                      'Clear All',
                      style: GoogleFonts.poppins(
                        fontSize: getResponsiveFontSize(context, 12),
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          _buildSearchHistoryList(),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final isTablet = this.isTablet(context);
    final padding = getResponsivePadding(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = firebase_auth.FirebaseAuth.instance.currentUser;

          return Row(
            children: [
              Container(
                width: isTablet ? 80 : 60,
                height: isTablet ? 80 : 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: user?.photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          user!.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              color: Colors.white,
                              size: isTablet ? 40 : 30,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: Colors.white,
                        size: isTablet ? 40 : 30,
                      ),
              ),
              SizedBox(width: isTablet ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'User',
                      style: GoogleFonts.poppins(
                        fontSize: getResponsiveFontSize(context, 20),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isTablet ? 8 : 4),
                    Text(
                      user?.email ?? 'No email',
                      style: GoogleFonts.poppins(
                        fontSize: getResponsiveFontSize(context, 14),
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: getResponsiveFontSize(context, 20),
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildFavoriteCitiesList() {
    final isTablet = this.isTablet(context);

    if (favoriteCities.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        ),
        child: Center(
          child: Text(
            'No favorite cities yet',
            style: GoogleFonts.poppins(
              fontSize: getResponsiveFontSize(context, 16),
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: favoriteCities.length,
        itemBuilder: (context, index) {
          final city = favoriteCities[index];
          return ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: isTablet ? 8 : 4,
            ),
            leading: Icon(
              Icons.location_on,
              color: Colors.white,
              size: isTablet ? 28 : 24,
            ),
            title: Text(
              city['city'] ?? '',
              style: GoogleFonts.poppins(
                fontSize: getResponsiveFontSize(context, 16),
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              city['country'] ?? '',
              style: GoogleFonts.poppins(
                fontSize: getResponsiveFontSize(context, 14),
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            trailing: IconButton(
              onPressed: () async {
                await _firestoreService.removeFavoriteCity(city['city']);
                _loadUserData();
              },
              icon: Icon(
                Icons.delete,
                color: Colors.red.withValues(alpha: 0.8),
                size: isTablet ? 28 : 24,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchHistoryList() {
    final isTablet = this.isTablet(context);

    if (searchHistory.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isTablet ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history,
                color: Colors.white.withValues(alpha: 0.5),
                size: isTablet ? 48 : 40,
              ),
              SizedBox(height: isTablet ? 12 : 8),
              Text(
                'No search history yet',
                style: GoogleFonts.poppins(
                  fontSize: getResponsiveFontSize(context, 16),
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: isTablet ? 4 : 2),
              Text(
                'Search for cities to see your history here',
                style: GoogleFonts.poppins(
                  fontSize: getResponsiveFontSize(context, 12),
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: searchHistory.length,
        itemBuilder: (context, index) {
          final search = searchHistory[index];
          return ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: isTablet ? 8 : 4,
            ),
            leading: Icon(
              Icons.search,
              color: Colors.white,
              size: isTablet ? 28 : 24,
            ),
            title: Text(
              search['city'] ?? '',
              style: GoogleFonts.poppins(
                fontSize: getResponsiveFontSize(context, 16),
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              'Searched on ${search['timestamp'] ?? ''}',
              style: GoogleFonts.poppins(
                fontSize: getResponsiveFontSize(context, 14),
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showClearHistoryDialog(BuildContext context) async {
    final isTablet = this.isTablet(context);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF667eea),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        ),
        title: Text(
          'Clear History',
          style: GoogleFonts.poppins(
            fontSize: getResponsiveFontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to clear all search history? This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: getResponsiveFontSize(context, 14),
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                fontSize: getResponsiveFontSize(context, 14),
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _firestoreService.deleteWeatherHistory();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Search history cleared successfully',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadUserData(); // Reload data
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error clearing history: $e',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Clear',
              style: GoogleFonts.poppins(
                fontSize: getResponsiveFontSize(context, 14),
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
