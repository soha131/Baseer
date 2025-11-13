# Baseer

An intelligent healthcare application that helps patients manage medications, connect with pharmacists, and improve medication adherence through AI-powered features.

---

## 🧭 Overview

Baseer is a comprehensive Flutter-based mobile healthcare application designed to bridge the gap between patients and pharmacists. The system combines medication management, OCR-based drug detection, real-time communication, and intelligent reminders to ensure better health outcomes.

---

## ✨ Key Features


•	🔍 OCR Drug Detection - Scan prescriptions to automatically identify medications
•	💊 Smart Reminders - Schedule and track medication intake with push notifications
•	💬 Real-time Chat - Direct communication between patients and pharmacists
•	📊 Adherence Tracking - Visual statistics on medication compliance
•	🎤 Voice Accessibility - Speech-to-text and text-to-speech for enhanced accessibility
•	👤 Multi-Role System - Separate interfaces for Patients, Pharmacists, and Admins
•	🔐 Biometric Authentication - Secure login with fingerprint/face recognition

---

## 🛠️ Tech Stack
Frontend
•	Flutter (3.0+) - Cross-platform mobile framework
•	Dart - Programming language
•	BLoC Pattern (flutter_bloc) - State management
•	Material Design - UI/UX components
Backend & Cloud Services
•	Firebase Authentication - User authentication with email/password
•	Cloud Firestore - NoSQL database for real-time data
•	Firebase Cloud Messaging (FCM) - Push notifications
•	Firebase Storage - Profile images and medical documents
AI & Machine Learning
•	Python FastAPI - OCR backend service (Port 8000)
•	OCR Engine - Prescription text extraction
•	Drug Database - Medication information retrieval



---

## 📸 Screenshots

![](assets/screenshots/Screenshot_2025-11-13-22-19-48-976_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-19-51-669_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-19-57-139_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-19-59-374_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-20-48-115_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-20-53-616_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-21-20-225_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-21-23-095_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-28-05-849_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-28-31-946_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-28-41-527_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-28-45-919_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-28-52-253_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-29-12-373_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-29-14-863_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-29-42-895_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-29-47-454_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-29-52-131_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-30-07-484_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-30-12-066_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-30-40-797_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-30-44-455_com.example.baseer.jpg)
![](assets/screenshots/Screenshot_2025-11-13-22-30-49-494_com.example.baseer.jpg)


---

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/soha131/Baseer.git
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
flutter run
```

> Make sure your environment is set up with Flutter SDK.

---

## 🧩 Folder Structure

```

lib/
├── admin_screens/              # Admin-specific UI
│   ├── admin_home.dart
│   ├── admin_notification.dart
│   ├── view_users.dart
│   └── user_info.dart
├── auth_screens/               # Authentication flows
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── ProfileScreen.dart
│   └── forget_password_screen.dart
├── user_screens/               # Patient interface
│   ├── user_home.dart
│   ├── medication_reminder_screen.dart
│   ├── view_medicines_screen.dart
│   ├── scan_screen.dart
│   ├── medical_report.dart
│   ├── view_pharmacists.dart
│   └── patient_reports_screen.dart
├── pharmacist_screens/         # Pharmacist interface
│   ├── pharmacist_home.dart
│   ├── view_patients.dart
│   ├── patient_info.dart
│   └── pharmacist_reports_screen.dart
├── core/                       # Business logic
│   ├── ocr_detect_cubit.dart
│   ├── ocr_detect_state.dart
│   └── drug_detect_model.dart
├── notifications/              # FCM & Local notifications
│   ├── notification_service.dart
│   └── notifications_screen.dart
├── widgets/                    # Reusable components
│   ├── widget_notification.dart
│   ├── widget_chat.dart
│   └── widget_medicines_time.dart
├── first_screens/              # Onboarding
│   ├── splash_screen.dart
│   └── welcome_screen.dart
├── chat_screen.dart            # Real-time messaging
├── routes.dart                 # Navigation management
└── main.dart                   # App entry point

```


## 📅 Future Enhancements
   -  🌍 Multi-Language Support - Expand beyond Arabic/English for global accessibility
   -  📴 Offline Mode - Local caching for uninterrupted access to medication data
   - 🤖 AI Health Insights - Personalized health recommendations based on medication history
   - 📄 PDF Reports - Export medication logs and adherence reports

---

## 🤝 Contributing

Contributions are welcome!  
Please open an issue or submit a pull request to help improve the project.

---

## 📄 License

This project is licensed under the **MIT License** — feel free to use and modify it.

---
