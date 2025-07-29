# 🌤️ Weather Pro - Flutter Weather App

A beautiful, responsive weather application built with Flutter that provides real-time weather data, 5-day forecasts, and user management features.

## ✨ Features

### 🌟 Core Features
- **Real-time Weather Data**: Get current weather conditions for any city
- **5-Day Forecast**: View detailed weather predictions for the next 5 days
- **Location-based Forecasts**: Accurate weather data based on location
- **Save Favorite Cities**: Bookmark your frequently checked cities
- **Detailed Weather Analytics**: Comprehensive weather information

### 🔐 Authentication
- **Google Sign-in**: Secure authentication using Google accounts
- **User Profiles**: Personalized experience with user data
- **Cross-platform**: Works on Android, iOS, and Web

### 📱 User Experience
- **Responsive Design**: Optimized for phones, tablets, and web browsers
- **Beautiful Animations**: Smooth Lottie animations for weather conditions
- **Modern UI**: Material Design 3 with custom gradients
- **Search History**: Track your previous weather searches
- **Clean Interface**: Intuitive and user-friendly design

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd weather_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Follow the instructions in `FIREBASE_SETUP.md`
   - Configure Firebase Authentication and Firestore
   - Add your Firebase configuration files

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Platform Support

- ✅ **Android**: Full support with Google Sign-in
- ✅ **iOS**: Full support with Google Sign-in  
- ✅ **Web**: Limited Google Sign-in (requires additional configuration)

## 🛠️ Technical Stack

- **Framework**: Flutter 3.8.1
- **State Management**: Provider
- **Backend**: Firebase (Auth + Firestore)
- **Weather API**: OpenWeatherMap
- **UI Components**: Material Design 3
- **Animations**: Lottie
- **Fonts**: Google Fonts (Poppins)

## 📁 Project Structure

```
lib/
├── main.dart                 # Main app entry point
├── firebase_options.dart     # Firebase configuration
├── screens/
│   ├── login_screen.dart     # Authentication screen
│   └── profile_screen.dart   # User profile & history
├── providers/
│   └── auth_provider.dart    # Authentication state management
└── services/
    ├── auth_service.dart     # Firebase authentication
    └── firestore_service.dart # Firestore database operations
```

## 🎨 Features in Detail

### Weather Display
- Current temperature, humidity, wind speed
- Weather condition with animated icons
- Sunrise/sunset times
- Feels like temperature

### 5-Day Forecast
- Daily average temperatures
- Weather condition predictions
- Smart data grouping and averaging
- Beautiful visual presentation

### User Management
- Google Sign-in integration
- Favorite cities management
- Search history tracking
- Profile information display

## 🔧 Configuration

### API Keys
- OpenWeatherMap API key is included for development
- For production, use your own API key

### Firebase Setup
- Authentication enabled for Google Sign-in
- Firestore database for user data storage
- Security rules configured for user data protection

## 📊 Performance

- **Responsive Design**: Adapts to all screen sizes
- **Fast Loading**: Optimized API calls and caching
- **Smooth Animations**: 60fps animations with Lottie
- **Efficient State Management**: Minimal rebuilds with Provider

## 🎯 Future Enhancements

- [ ] Push notifications for weather alerts
- [ ] Offline weather data caching
- [ ] Multiple language support
- [ ] Dark/Light theme toggle
- [ ] Weather widgets for home screen
- [ ] Location-based automatic weather updates

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

For support and questions:
- Create an issue in the repository
- Check the Firebase setup guide
- Review the code documentation

---

**Built with ❤️ using Flutter**

