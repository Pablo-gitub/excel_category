# ExcelCategory

Welcome to ExcelCategory! This application allows you to easily view and filter Excel files across multiple platforms. It has been realized with Flutter.

### 🌐 Web Version
You can access the web version of the app [here](https://excelcategory.web.app). This version allows users to upload and filter Excel files directly from their browsers.

### 📱 Mobile Versions
- **[Android & iOS v1.0.16](https://github.com/Pablo-gitub/excel_category/releases/tag/v1.0.16)**: The Android version can be installed on any compatible device. However, please note that the iOS version is uncertified. It can only be installed on jailbroken devices or by those familiar with alternative installation methods.

### 💻 Desktop Versions
- **[Desktop v1.0.16](https://github.com/Pablo-gitub/excel_category/releases/tag/desktop-v1.0.16)**: The app is also available for **MacOS**, **Linux**, and **Windows** in downloadable ZIP files. Each ZIP file contains the build files for the corresponding platform, making it easy to run the app on your desktop.

> **Note:** The links provided above may not point to the latest version of the app. Please check the [releases page](https://github.com/Pablo-gitub/excel_category/releases) for the most recent updates.

Feel free to explore the app on your preferred platform, and thank you for checking out ExcelCategory!

## Building Instructions
In .github/workflows you can find the Flutter build action files on github for three different specific case 
### console.yml
this file allow you to release desktop version Windows, MacOS and Linux
### dart.yml
this file allow you to release iOS version
### iosAndroid.yml
this file allow you to release mobile version iOS and Android

'''
name: "Desktop Build & Release"

on:
  push:
    branches:
      - main
      - develop
  pull_request:
    branches:
      - main
      - develop
'''

this part specify when you want the release to get update

'''
jobs:
  build-linux:
    name: Build Linux
    runs-on: ubuntu-latest
    steps:
      - name: Clone repository
        uses: actions/checkout@v4
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
      - name: Install Linux Dependencies
        run: |
          sudo apt-get update -y
          sudo apt-get install -y ninja-build libgtk-3-dev
      - name: Install project dependencies
        run: flutter pub get
      - name: Build Linux
        run: flutter build linux --release
      - name: Archive Linux Build
        run: zip -r linux-build.zip build/linux/x64/release/bundle/
      - name: Upload Linux Build Artifact
        uses: actions/upload-artifact@v4
        with:
          name: linux-build
          path: linux-build.zip
'''

## Important Points About This Portion of the GitHub Actions Configuration for Linux Build
### Cloning the Repository
*Importance*: Cloning the repository is the first step to ensure that the latest version of the code is available for the build. Without this step, the workflow would not have access to the project files.
### Setting Up Flutter
*Details*: This step uses the 'subosito/flutter-action' to set up Flutter, specifying the stable channel. This ensures that the versions of Flutter being used are reliable and well-tested.
### Installing Linux Dependencies
*Details*: Installing dependencies such as 'ninja-build' and 'libgtk-3-dev' is crucial for correctly compiling the application on Linux. Specifying necessary dependencies helps prevent compilation errors during the build phase.
### Installing Project Dependencies
*Importance*: Running 'flutter pub get' ensures that all the dependencies specified in the 'pubspec.yaml' file are installed, allowing the application to compile correctly.
### Building the Application
*Details*: The command 'flutter build linux --release compiles the app in release mode, optimizing performance and reducing the size of the resulting package. This step is critical for distributing the app to end users.
### Archiving the Build
*Reason for Zipping*: Creating a zip archive of the build helps prevent duplicate files and makes distribution easier. A compact zip file simplifies downloading and managing artifacts.
### Uploading the Build Artifact
*Importance*: Using 'actions/upload-artifact' allows you to save the build artifact (the zip file) so that it can be easily downloaded later. This is useful for releasing and debugging built versions.

'''
build-windows:
    name: Build Windows
    runs-on: windows-latest
    steps:
      - name: Clone repository
        uses: actions/checkout@v4
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
      - name: Install project dependencies
        run: flutter pub get
      - name: Build Windows
        run: flutter build windows --release
      - name: Archive Windows Build
        run: Compress-Archive -Path build/windows/x64/runner/Release -DestinationPath windows-build.zip
      - name: Upload Windows Build Artifact
        uses: actions/upload-artifact@v4
        with:
          name: windows-build
          path: windows-build.zip

  build-macos:
    name: Build macOS
    runs-on: macos-latest
    steps:
      - name: Clone repository
        uses: actions/checkout@v4
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
      - name: Install project dependencies
        run: flutter pub get
      - name: Build macOS
        run: flutter build macos --release
      - name: Archive macOS Build
        run: zip -r macos-build.zip build/macos/Build/Products/Release/
      - name: Upload macOS Build Artifact
        uses: actions/upload-artifact@v4
        with:
          name: macos-build
          path: macos-build.zip
'''

Windows and macOS builds share similarities with the Linux build process but have key distinctions due to their operating system environments and specific requirements. Here’s a comparison highlighting the differences:

> **Note:** Building for macOS requires a macOS environment, as the Flutter build process relies on tools such as Xcode that are only available on Mac computers. Ensure you are running the build on a compatible Mac machine to avoid errors during the build process.

## Distinctions
## Environment
*Windows*: Runs on 'windows-latest', leveraging Windows-specific tools and commands for the build process.
*macOS*: Runs on 'macos-latest', tailored for Apple's ecosystem, which may include different handling of file permissions and app signing.
## Build Command
*Windows*: Uses 'flutter build windows --release' to create a release build optimized for Windows.
*macOS*: Uses 'flutter build macos --release', which may involve additional steps for signing and packaging the app for distribution on macOS.
## Archiving the Build
*Windows*: Uses the 'Compress-Archive' command to zip the build output directory.
*macOS*: Uses the 'zip -r' command to create a zip archive of the build products, with different paths and structures.
## Output Path
The output paths differ for Windows and macOS, reflecting the specific file structures and naming conventions of each operating system.
