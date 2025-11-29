# Ampere ⚡

**Ampere** is a high-performance, native audio player that reimagines the modular soul of Winamp for the modern era.

It is built with a strict **"No Electron / No WebView"** policy. We prioritize raw performance, low memory footprint, and audiophile-grade sound processing.

-----

## 🚀 The Philosophy

1.  **Speed is a Feature:** Instant startup, zero latency UI, and minimal RAM usage.
2.  **Native is King:** We use native OS rendering (Metal on Mac, DirectX on Windows) for butter-smooth 120Hz+ visualizers.
3.  **Skinnable Core:** The UI is decoupled from the player logic, allowing for infinite customization without sacrificing performance.

## 🛠 Tech Stack (The "Bleeding Edge" Native)

To achieve maximum throughput and safety, Ampere uses a **Hybrid Native** architecture:

  * **Core Logic & Audio Engine:** **Rust** (utilizing `cpal` or `rodio` for low-level stream management). Rust ensures memory safety without garbage collection pauses.
  * **Data Interop:** **UniFFI** (to compile the Rust core into bindings for Swift and C\#).
  * **macOS Frontend:** **Swift / SwiftUI** (Directly binding to the Rust core).
  * **Windows Frontend:** **C\# / WinUI 3** (Windows App SDK).

*Why this stack?* This approach shares 90% of the business logic and audio processing code while using the absolute fastest UI framework available for each specific Operating System.

## ✨ Features (MVP)

  * [ ] **Zero-Latency Playback:** Gapless playback support for FLAC, MP3, WAV, OGG, and AAC.
  * [ ] **Modular UI:** Snap, dock, and float windows just like the classic.
  * [ ] **Hardware Accelerated Visualizers:** GPU-based audio visualization utilizing raw FFT data.
  * [ ] **10-Band EQ:** Native DSP processing.
  * [ ] **Global Hotkeys:** Control your music without leaving your IDE.

## 📦 Building form Source

### Prerequisites

  * **Rust Toolchain:** `rustup update stable`
  * **macOS:** Xcode 15+
  * **Windows:** Visual Studio 2022 (Desktop Development with C++)

### Quick Start

1.  **Clone the repo:**

    ```bash
    git clone https://github.com/makalin/ampere.git
    cd ampere
    ```

2.  **Build the Core (Rust):**

    ```bash
    cd core
    cargo build --release
    ```

3.  **Run the Client:**

      * *Mac:* Open `ios/Ampere.xcodeproj` and hit Run.
      * *Windows:* Open `windows/Ampere.sln` and hit F5.

## 🤝 Contributing

We welcome audiophiles, C++ veterans, and Rustaceans.

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingVisualizer`)
3.  Commit your Changes (`git commit -m 'Add GPU acceleration'`)
4.  Push to the Branch (`git push origin feature/AmazingVisualizer`)
5.  Open a Pull Request

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.

## 👨‍💻 Author

**Mehmet T. AKALIN**

  * **GitHub:** [@makalin](https://github.com/makalin)
  * **Company:** [Digital Vision (dv.com.tr)](https://dv.com.tr)
  * **LinkedIn:** [Mehmet T. AKALIN](https://www.linkedin.com/in/makalin/)
  * **X (Twitter):** [@makalin](https://x.com/makalin)

-----

*Inspired by the Llama.* 🦙
