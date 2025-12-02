# Ampere ⚡

**The Ultimate Professional Audio Player** - Winamp-style interface with advanced features, plugin support, and JavaScript automation.

---

## 🎯 Overview

Ampere is a professional-grade audio player for macOS featuring an authentic Winamp-style interface. Built with Swift and AVFoundation, it provides advanced audio processing, playlist management, online integration, and extensibility through JavaScript automation and plugins.

---

## 🚀 Features

### Core Playback
- ✅ **Multi-format Support**: MP3, FLAC, WAV, OGG, AAC, M4A
- ✅ **Gapless Playback**: Seamless transitions between tracks
- ✅ **Seek/Position Control**: Jump to any position with precision
- ✅ **Volume Control**: 0-100% with smooth transitions
- ✅ **Playback State Persistence**: Remembers position and settings

### Playback Modes
- ✅ **Song Loop**: Repeat single track (Repeat Mode: One)
- ✅ **Playlist Loop**: Repeat entire playlist (Repeat Mode: All)
- ✅ **Random Play**: Shuffle mode for random track order
- ✅ **Normal Play**: Play once through playlist (Repeat Mode: None)
- ✅ **Auto-advance**: Automatically plays next track when current ends
- ✅ **Crossfade**: Smooth transitions between tracks (0-10 seconds)

### Equalizer & Audio Processing
- ✅ **10-Band Equalizer**: -12dB to +12dB per band
  - Frequencies: 60Hz, 170Hz, 310Hz, 600Hz, 1K, 3K, 6K, 12K, 14K, 16K
- ✅ **Real-Time Spectrum Analyzer**: FFT-based frequency visualization with animated display
- ✅ **Audio Effects**:
  - **Reverb**: Wet/Dry Mix (0-100%)
  - **Delay**: Time (0-2s), Feedback (-100% to +100%)
  - **Chorus**: Depth (0-100%), Rate (0.1-20 Hz)
  - **Distortion**: Pre-Gain (-80dB to +20dB)
- ✅ **3D Spatial Audio**: 
  - Azimuth (-180° to +180°)
  - Elevation (-90° to +90°)
  - Distance (0.1m to 10m)
  - Surround modes (Linear, Inverse, Exponential)
- ✅ **Channel Support**: 
  - Stereo, Mono, Surround modes
  - Balance control (-1.0 to +1.0)
- ✅ **ReplayGain Support**: 
  - Track gain, Album gain, Auto mode
  - Pre-amp adjustment (-20dB to +20dB)
  - Automatic volume normalization

### Playlist Management
- ✅ **Playlist Persistence**: Remembers last played track, repeat/shuffle modes
- ✅ **Playlist Grouping**: Organize by:
  - Artist
  - Album
  - Genre
  - Year
  - Date Added
  - Play Count
  - Rating
- ✅ **Drag & Drop**: Add files by dragging into playlist window
- ✅ **Import/Export**: M3U playlist format support
- ✅ **Online Playlist Import**: Spotify, Deezer playlists
- ✅ **Online Playlist Export**: Export to Spotify
- ✅ **Metadata Extraction**: Automatic title, artist, album, genre, year extraction

### Search & Discovery
- ✅ **Unified Search**: Search local files and online services simultaneously
- ✅ **Online Services Integration**:
  - Spotify (search, import/export playlists)
  - Deezer (search, import playlists)
  - YouTube Music (search)
- ✅ **Daily Suggestions**: AI-powered recommendations based on listening history
  - Play frequency analysis
  - Recency weighting
  - Time-of-day patterns
  - Discovery boost for new tracks
- ✅ **Daily Playlist Export**: Export suggested playlists as M3U files
- ✅ **Smart Recommendations**: Based on play count, recency, time patterns

### Analytics & Statistics
- ✅ **Listening Analytics**: Comprehensive listening statistics
  - Total tracks played, unique tracks, listening time
  - Top tracks, genres, and artists
  - Listening patterns by hour and day
  - Session tracking and completion rates
  - Play count and average play time per track

### Automation & Extensibility
- ✅ **JavaScript Automation**: Full scripting support for player control
- ✅ **Plugin System**: Extend functionality with custom plugins
- ✅ **API Access**: Control player, EQ, playlist via JavaScript
- ✅ **Console Logging**: Debug scripts with console.log
- ✅ **Plugin Manager**: Load and manage JavaScript plugins

### JavaScript API Reference

```javascript
// Player Control
Ampere.play()              // Play current track
Ampere.pause()             // Pause playback
Ampere.stop()              // Stop playback
Ampere.next()              // Play next track
Ampere.previous()          // Play previous track

// Volume & Position
Ampere.setVolume(0.5)      // Set volume (0.0 to 1.0)
Ampere.getVolume()         // Get current volume
Ampere.seek(120.5)         // Seek to position (seconds)
Ampere.getPosition()       // Get current position (seconds)
Ampere.getDuration()       // Get track duration (seconds)

// File Management
Ampere.loadFile("/path/to/song.mp3")           // Load audio file
Ampere.addToPlaylist("/path/to/song.mp3")       // Add file to playlist

// Equalizer
Ampere.setEQBand(5, 6.0)   // Set EQ band (0-9), gain (-12 to +12 dB)

// Logging
console.log("Message")     // Log message to console
```

### UI Features
- ✅ **Winamp-Style Interface**: Authentic retro design with modular windows
- ✅ **Modular Windows**: 
  - Main Player
  - Equalizer (EQ)
  - Playlist (LIST/PL)
  - Settings (SET)
  - Album Art (ART)
  - Lyrics (LYR)
  - Search (SRCH)
- ✅ **Draggable Windows**: Position windows anywhere on screen
- ✅ **Theme System**: 6 built-in themes + custom theme support
  - Light
  - Dark
  - High Contrast
  - Blue
  - Green
  - Purple
- ✅ **Real-Time Visualization**: 
  - Spectrum analyzer (20-band)
  - EQ frequency display (10-band)
  - Waveform visualization
- ✅ **Metadata Display**: 
  - Title, Artist, Album
  - Album Art (with dedicated window)
  - Lyrics (with dedicated window)
  - Genre, Year, Track Number

### Online Integration
- ✅ **Spotify Search**: Find tracks on Spotify
- ✅ **Deezer Search**: Search Deezer catalog
- ✅ **YouTube Music Search**: Find videos and music
- ✅ **Playlist Import**: Import playlists from online services
- ✅ **Playlist Export**: Export playlists to online services

---

## 📦 Building

### macOS

1. **Open Project**
   ```bash
   open macos/Ampere/Ampere.xcodeproj
   ```

2. **Build and Run**
   - Press `⌘R` in Xcode, or
   - Select Product → Run from menu

### Requirements

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later

### Build Configuration

The project uses:
- **AVFoundation** for audio playback
- **AVAudioEngine** for DSP processing
- **JavaScriptCore** for plugin system
- **SwiftUI** for user interface

---

## 🔧 Configuration

### Online Services API Keys

To enable online search and playlist import/export, edit `macos/Ampere/Ampere/OnlineSearchService.swift` and add your API keys:

#### Spotify
1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Create a new app
3. Copy Client ID and Client Secret
4. Add to `OnlineSearchService.swift`:
   ```swift
   private let spotifyClientID = "YOUR_CLIENT_ID"
   private let spotifyClientSecret = "YOUR_CLIENT_SECRET"
   ```

#### Deezer
1. Go to [Deezer Developers](https://developers.deezer.com)
2. Register your app
3. Copy App ID
4. Add to `OnlineSearchService.swift`:
   ```swift
   private let deezerAppID = "YOUR_APP_ID"
   ```

#### YouTube Music
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Enable YouTube Data API v3
3. Create API Key
4. Add to `OnlineSearchService.swift`:
   ```swift
   private let youtubeAPIKey = "YOUR_API_KEY"
   ```

---

## 📝 Usage Guide

### Basic Playback

1. **Load File**
   - Click **LOAD** button to open file picker
   - Or drag & drop audio files onto player window

2. **Playback Controls**
   - ▶️ **Play/Pause**: Toggle playback
   - ⏹️ **Stop**: Stop and reset to beginning
   - ⏭️ **Next**: Play next track in playlist
   - ⏮️ **Previous**: Play previous track in playlist

3. **Volume Control**
   - Use volume slider in main player
   - Or adjust in Settings → Audio tab

### Equalizer

1. Click **EQ** button to open equalizer window
2. Adjust 10 frequency bands using vertical sliders
3. Green = positive gain, Red = negative gain
4. View real-time spectrum analyzer display
5. Toggle EQ on/off in Settings

### Playlist

1. **Open Playlist**
   - Click **LIST** or **PL** button
   - Or use keyboard shortcut (if configured)

2. **Add Tracks**
   - Drag & drop files into playlist window
   - Click **ADD** button for file picker
   - Use **SRCH** to search and add online tracks

3. **Playlist Controls**
   - **NONE/ONE/ALL**: Cycle repeat modes
     - NONE: Play once through playlist
     - ONE: Loop current track
     - ALL: Loop entire playlist
   - **SHUFFLE**: Toggle random play mode
   - **GROUP**: Organize tracks by category
   - **SUGGEST**: View daily recommendations

4. **Play Track**
   - Click any track in playlist to play
   - Double-click to play immediately

### Search

1. Click **SRCH** button to open search window
2. Enter search query
3. Select source:
   - **Local**: Search local files
   - **Spotify**: Search Spotify catalog
   - **Deezer**: Search Deezer catalog
   - **YouTube Music**: Search YouTube
4. Click track to:
   - **Play** (local files)
   - **Add to Playlist** (online tracks)

### Daily Suggestions

1. Open playlist window
2. Click **SUGGEST** button
3. View daily recommended tracks based on:
   - Your listening history
   - Play frequency
   - Time-of-day patterns
   - Discovery opportunities
4. Click **EXPORT** to save suggested playlist as M3U file

### Playlist Grouping

1. Open playlist window
2. Click **GROUP** button
3. Select grouping type:
   - Artist
   - Album
   - Genre
   - Year
   - Date Added
   - Play Count
   - Rating
4. Browse grouped tracks
5. Use search to filter within groups

### Repeat & Shuffle

1. Open playlist window
2. Click **NONE/ONE/ALL** to cycle repeat modes:
   - **NONE**: Play once, stop at end
   - **ONE**: Loop current track indefinitely
   - **ALL**: Loop entire playlist
3. Click **SHUFFLE** to toggle random play:
   - **OFF**: Play in order
   - **ON**: Play in random order

### Crossfade

1. Click **SET** button to open settings
2. Go to **Audio** tab
3. Enable **Crossfade**
4. Adjust **Duration** slider (0-10 seconds)
5. Tracks will smoothly fade out and fade in when transitioning

### ReplayGain

1. Click **SET** button
2. Go to **Audio** tab
3. Select **ReplayGain Mode**:
   - **Off**: No normalization
   - **Track**: Use track gain tags
   - **Album**: Use album gain tags
   - **Auto**: Automatically choose best mode
4. Adjust **Pre-Amp** if needed (-20dB to +20dB)
5. Volume is automatically adjusted based on ReplayGain tags in files

### Audio Effects

1. Click **SET** button to open settings
2. Go to **Audio** tab
3. Click **Audio Effects** button
4. Enable and adjust:
   - **Reverb**: Add room ambience
   - **Delay**: Echo effect
   - **Chorus**: Thickening effect
   - **Distortion**: Overdrive effect

### 3D Spatial Audio

1. Click **SET** button
2. Go to **Audio** tab
3. Click **3D Sound Settings** button
4. Enable 3D Spatial Audio
5. Adjust:
   - **Azimuth**: Horizontal position (-180° to +180°)
   - **Elevation**: Vertical position (-90° to +90°)
   - **Distance**: Distance from listener (0.1m to 10m)
   - **Surround Mode**: Distance attenuation model

### Channel Settings

1. Click **SET** button
2. Go to **Audio** tab
3. Adjust **Channel Mode**:
   - **Stereo**: Standard stereo playback
   - **Mono**: Combine to mono
   - **Surround**: Surround sound processing
4. Adjust **Balance**: -1.0 (left) to +1.0 (right)

### Plugins & Automation

1. Click **SET** button
2. Go to **Plugins** tab
3. Click **Plugin Manager**
4. View loaded plugins and JavaScript API reference
5. Click **SCRIPT** to open JavaScript editor
6. Write automation scripts:
   ```javascript
   // Example: Auto-adjust volume by time
   function autoVolume() {
       const hour = new Date().getHours();
       if (hour >= 22 || hour < 7) {
           Ampere.setVolume(0.3);  // Quiet at night
       } else {
           Ampere.setVolume(0.8);  // Normal during day
       }
   }
   setInterval(autoVolume, 60000);
   ```
7. Click **RUN** to execute script

### Themes

1. Click **SET** button
2. Go to **Themes** tab
3. Select from built-in themes:
   - Light
   - Dark
   - High Contrast
   - Blue
   - Green
   - Purple
4. Theme applies immediately

### Album Art & Lyrics

1. **Album Art**
   - Click **ART** button to open album art window
   - Displays artwork from file metadata
   - Automatically updates when track changes

2. **Lyrics**
   - Click **LYR** button to open lyrics window
   - Displays lyrics from file metadata
   - Scrollable text view

### Listening Analytics

1. Click **SET** button
2. Go to **Analytics** tab
3. Click **View Analytics** to see:
   - Overall statistics (total tracks, listening time, etc.)
   - Top tracks by play count
   - Top genres and artists
   - Listening patterns (peak hours, day of week)
4. Click **Reset Statistics** to clear all data

---

## 🔌 Plugin Development

### Creating Plugins

Plugins are JavaScript files that extend Ampere's functionality.

1. **Plugin Location**
   - Create directory: `~/.ampere/plugins/`
   - Place `.js` files in this directory

2. **Plugin Structure**
   ```javascript
   // my-plugin.js
   // Auto-fade volume on track end
   function fadeOut() {
       let volume = Ampere.getVolume();
       if (volume > 0.1) {
           Ampere.setVolume(volume - 0.1);
           setTimeout(fadeOut, 100);
       }
   }
   
   // Hook into track end (example)
   // Note: Actual event hooks depend on plugin system implementation
   ```

3. **Loading Plugins**
   - Plugins in `~/.ampere/plugins/` are auto-loaded
   - Or use Plugin Manager to load manually

### JavaScript API

See **JavaScript API Reference** section above for complete API documentation.

---

## 📊 Daily Suggestions Algorithm

The daily suggestions system uses a scoring algorithm based on:

1. **Play Frequency**: Tracks played more often get higher scores
2. **Recency**: Recently played tracks are boosted
3. **Time Patterns**: Tracks played at similar times of day are suggested
4. **Discovery**: Never-played tracks get a boost for exploration

The algorithm generates a daily playlist mixing:
- **Favorites**: Your most-played tracks
- **Discoveries**: New tracks you haven't heard yet

---

## 🎯 Roadmap

Future features planned:

- [ ] Visualizer plugins (custom visualizations)
- [ ] MIDI support
- [ ] Network streaming (Shoutcast, Icecast)
- [ ] Cloud sync (iCloud, Dropbox)
- [x] Advanced analytics (listening statistics) ✅
- [ ] Social features (share playlists, recommendations)
- [x] Crossfade between tracks ✅
- [x] ReplayGain support ✅
- [ ] CD ripping
- [ ] Podcast support

---

## 🐛 Troubleshooting

### No Sound Output

1. Check system volume
2. Verify audio file format is supported
3. Check Settings → Audio → Volume
4. Restart application

### Playback Not Starting

1. Ensure file exists and is accessible
2. Check file permissions
3. Try loading a different file
4. Check console for error messages

### EQ Not Working

1. Verify EQ is enabled in Settings
2. Check EQ window is open
3. Ensure audio is playing
4. Try resetting EQ to default

### Playlist Not Saving

1. Check app has write permissions
2. Verify UserDefaults is accessible
3. Try manually saving (if option available)

---

## 📄 License

This project is licensed under the MIT License.

**Copyright © 2025 Mehmet T. AKALIN**

See [LICENSE](LICENSE) file for full license text.

---

## 🤝 Contributing

Contributions are welcome! This is a professional-grade audio player built for power users.

### How to Contribute

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Areas for Contribution

- Bug fixes
- New features
- Performance improvements
- Documentation
- UI/UX enhancements
- Plugin development

---

## 👤 Author

**Mehmet T. AKALIN**

- Created and maintained by Mehmet T. AKALIN
- Professional audio player for macOS
- Built with Swift, AVFoundation, and SwiftUI

---

## 🙏 Acknowledgments

- Inspired by Winamp's classic interface
- Built with Apple's AVFoundation framework
- Uses JavaScriptCore for plugin system
- Thanks to the open-source community

---

## 📞 Support

For issues, questions, or feature requests:
- Check existing issues
- Create a new issue with detailed information
- Include system information and error logs

---

**Ampere ⚡ - The Ultimate Professional Audio Player**

*Created with ❤️ by Mehmet T. AKALIN*
