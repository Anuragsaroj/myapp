# Blueprint

## Overview

This document outlines the structure and implementation of a Sudoku game application built with Flutter. It includes details on the app's features, design, and architecture.

## Features

*   **Multiple Screens:** The app includes a splash screen, home screen, daily challenge screen, and profile screen.
*   **Theme Management:** The app supports both light and dark themes using the `provider` package.
*   **Bottom Navigation:** The main screen uses a bottom navigation bar to switch between the home, daily challenge, and profile screens.

## Design

*   **Themes:** The app uses custom light and dark themes defined in `lib/themes.dart`.
*   **Splash Screen:** A splash screen is displayed on app launch.

## Architecture

*   **State Management:** The app uses the `provider` package for state management, specifically for managing the app's theme.
*   **Screen Navigation:** The app uses a `BottomNavigationBar` to navigate between the main screens.

## Current Plan

I have corrected the dependency issue in the `pubspec.yaml` file and removed the unnecessary `UniqueKey` from `lib/main.dart`. These changes should resolve the "System UI isn't responding" error and improve the overall stability of the application.
