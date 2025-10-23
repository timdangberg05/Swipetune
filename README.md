# 🎵 Swipetune

**Discover music like never before** – A Flutter-based music discovery app that brings the familiar swipe interface to music exploration, powered by Spotify's vast music library.

## ✨ What Swipetune Does

Swipetune revolutionizes music discovery by combining the intuitive swipe gestures popularized by dating apps with music exploration. Users can swipe through personalized song recommendations, build their music library, and discover new tracks tailored to their taste.

### Key Features

- **🎯 Smart Music Discovery**: Swipe right to like, left to pass – discover music that matches your taste
- **🎧 Spotify Integration**: Seamless integration with Spotify's extensive music catalog
- **📚 Personal Library**: Organize and access your liked songs and playlists
- **🔐 Secure Authentication**: Multiple login options including Spotify OAuth
- **🎨 Beautiful UI**: Modern glass-morphism design with smooth animations
- **🔥 Real-time Sync**: Your preferences sync across devices via Firebase
- **📱 Cross-Platform**: Built with Flutter for iOS and Android

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter](https://flutter.dev/docs/get-started/install) (SDK >=3.2.0 <4.0.0)
- [Dart](https://dart.dev/get-dart)
- [Android Studio](https://developer.android.com/studio) or [Xcode](https://developer.apple.com/xcode/) (for device deployment)
- [Git](https://git-scm.com/)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/swipetune.git
   cd swipetune
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add your iOS and Android apps to the project
   - Download and place the configuration files:
     - `google-services.json` in `android/app/`
     - `GoogleService-Info.plist` in `ios/Runner/`

4. **Set up Spotify API**
   - Create a Spotify app at [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
   - Add your app's redirect URIs for authentication
   - Configure your API credentials in the app

5. **Run the app**
   ```bash
   flutter run
   ```

### Quick Start Example

```dart
// Basic usage - swipe through recommended tracks
final provider = context.read<SpotifyDataProvider>();
await provider.loadDiscoveryTracks();

// Like a track
provider.likeTrack();

// Access user's library
await provider.loadUserPlaylists();
```

## 🏗️ Project Structure

```
lib/
├── API/                    # External API clients
│   ├── SpotifyApiClient.dart
│   ├── SongService.dart
│   └── firebase_client.dart
├── auth/                   # Authentication logic
├── models/                 # Data models (Track, Playlist, etc.)
├── providers/              # State management
├── screens/                # App screens
│   ├── swipe_screen.dart   # Main swipe interface
│   ├── library_screen.dart # User's music library
│   └── main_screen.dart    # App navigation hub
├── services/               # Business logic services
├── widgets/                # Reusable UI components
└── main.dart              # App entry point
```

## 🛠️ Built With

### Core Technologies
- **[Flutter](https://flutter.dev/)** - Cross-platform UI framework
- **[Dart](https://dart.dev/)** - Programming language
- **[Provider](https://pub.dev/packages/provider)** - State management

### Key Dependencies
- **[just_audio](https://pub.dev/packages/just_audio)** - Audio playback
- **[cloud_firestore](https://pub.dev/packages/cloud_firestore)** - Real-time database
- **[cached_network_image](https://pub.dev/packages/cached_network_image)** - Image caching
- **[google_fonts](https://pub.dev/packages/google_fonts)** - Typography
- **[flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)** - Secure local storage

### API Integrations
- **Spotify Web API** - Music catalog and user data
- **Firebase** - User authentication and data sync
- **Deezer API** - Additional music metadata (optional)

## 📱 App Screens

### Main Features
- **Landing Screen**: Animated welcome with authentication options
- **Swipe Interface**: Core music discovery with card-based UI
- **Library Management**: Personal playlists and liked songs
- **User Settings**: Account management and preferences

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/AmazingFeature`
3. **Commit your changes**: `git commit -m 'Add some AmazingFeature'`
4. **Push to the branch**: `git push origin feature/AmazingFeature`
5. **Open a Pull Request**

### Development Guidelines
- Follow [Flutter style guide](https://dart.dev/guides/language/effective-dart/style)
- Write tests for new features
- Update documentation for API changes
- Ensure all tests pass before submitting PR

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support & Help

- **Documentation**: Check our [Wiki](../../wiki) for detailed guides
- **Issues**: Report bugs or request features in [Issues](../../issues)
- **Discussions**: Join conversations in [Discussions](../../discussions)
- **Email**: For private inquiries, contact [your-email@example.com]

## 🔗 Links

- [Spotify Developer Documentation](https://developer.spotify.com/documentation/web-api/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)

## 🙏 Acknowledgments

- Spotify for their comprehensive Web API
- Flutter team for the amazing framework
- The open-source community for invaluable packages and inspiration

---

**Made with ❤️ and Flutter** | [Report Bug](../../issues) | [Request Feature](../../issues)
