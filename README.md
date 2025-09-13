# Darents - Pet Activity Tracker

Darents is an iOS application designed to help pet owners (or "darents") keep track of their pets' activities. It allows users to create profiles for their pets, record activities like walks, feeding times, and medication, and share this information with other members of their household.

## Features

- **Pet Profiles:** Create and manage detailed profiles for each of your pets, including their name, breed, date of birth, and photo.
- **Activity Logging:** Record various activities for your pets, such as walks, meals, and medication, with optional notes.
- **Households:** Create households to share pet information and activities with other family members or caregivers.
- **Firebase Backend:** The app uses Firebase for real-time data synchronization, ensuring that your data is always up-to-date across all your devices and with all members of your household.
- **Google Sign-In:** Securely sign in to the app using your Google account.

## Architecture

The application is built using modern SwiftUI and follows the MVVM (Model-View-ViewModel) design pattern.

- **SwiftUI:** The user interface is built entirely with SwiftUI, Apple's modern declarative UI framework.
- **MVVM:** The app's architecture is based on MVVM, which helps to separate the UI (View) from the business logic (ViewModel) and the data (Model).
- **Firebase:** Firebase is used for the backend, including:
    - **Firestore:** A NoSQL database for storing all the application data.
    - **Firebase Storage:** For storing pet photos.
    - **Firebase Authentication:** For user authentication via Google Sign-In.
- **Repositories:** The app uses a generic repository pattern to abstract the direct interaction with Firestore, making the code cleaner and more testable.

## Setup and Installation

To run the project, you will need to have Xcode and CocoaPods installed.

1.  **Clone the repository:**
    ```
    git clone <repository_url>
    ```
2.  **Install dependencies:**
    Navigate to the project's root directory in the terminal and run the following command to install the necessary pods:
    ```
    pod install
    ```
    **Note:** If you don't have CocoaPods installed, you can install it using `sudo gem install cocoapods`.
3.  **Open the Xcode workspace:**
    Open the `.xcworkspace` file (not the `.xcodeproj` file) in Xcode.
4.  **Firebase Configuration:**
    This project requires a `GoogleService-Info.plist` file from a Firebase project. You will need to create your own Firebase project and add the configuration file to the `PetActivityTracker` directory in Xcode.
5.  **Run the app:**
    Build and run the app on a simulator or a physical device.
