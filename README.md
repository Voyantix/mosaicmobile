# Mosaic Desktop Template

A desktop-first Flutter template for individual PC and Mac game titles.

## Getting Started

This project is a single Flutter desktop application. It keeps only the Windows
and macOS runners so new game projects can start from a clean title template.

### Prerequisites

- Flutter SDK (>=3.5.0)
- Visual Studio with C++ desktop workload for Windows builds
- Xcode for macOS builds

### Run

1.  Install dependencies:
    ```bash
    flutter pub get
    ```
2.  Run on Windows:
    ```bash
    flutter run -d windows
    ```
3.  Run on macOS:
    ```bash
    flutter run -d macos
    ```

## Architecture

- **Desktop shell**: Fullscreen game window by default, with Windows and macOS
  platform runners.
- **Game flow**: Boot splash, main menu, story scenes, and the Mosaic game loop
  live in `lib/`.
- **Assets**: Runtime assets are grouped by purpose under `assets/audio/`,
  `assets/fonts/`, `assets/images/`, `assets/story/`, and `assets/video/`.

## Asset Attribution

All assets are property of Voyantix / Star Ascendant.
