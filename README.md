# Domotique App

Domotique App est une application Flutter multiplateforme (Android, iOS, Web, Desktop) permettant de contrôler et configurer des dispositifs ESP (IoT) pour la domotique.

## Fonctionnalités principales
- Découverte et gestion de dispositifs ESP
- Contrôle des pins et réglages personnalisés
- Notifications locales
- Gestion de la connectivité réseau
- Stockage local via SQLite
- Interface utilisateur moderne et responsive

## Structure du projet
```
lib/
  app.dart                # Point d'entrée de l'application
  main.dart               # Lancement de l'app
  models/                 # Modèles de données (esp_device, esp_pin)
  screens/                # Écrans principaux (home, device control, settings, etc.)
  services/               # Services (DB, réseau, notifications, foreground, etc.)
  widgets/                # Widgets réutilisables (ex: pin_card)
```

## Installation
1. **Cloner le dépôt**
   ```bash
   git clone https://github.com/olibouti/domotique_app.git
   cd domotique_app
   ```
2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```
3. **Lancer l'application**
   - Android/iOS :
     ```bash
     flutter run
     ```
   - Web :
     ```bash
     flutter run -d chrome
     ```
   - Desktop :
     ```bash
     flutter run -d windows # ou macos/linux selon la plateforme
     ```

## Dépendances principales
- [Flutter](https://flutter.dev/)
- [sqflite](https://pub.dev/packages/sqflite)
- [connectivity_plus](https://pub.dev/packages/connectivity_plus)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [workmanager](https://pub.dev/packages/workmanager)

## Contribution
Les contributions sont les bienvenues !
- Forkez le projet
- Créez une branche (`git checkout -b feature/ma-feature`)
- Commitez vos modifications
- Ouvrez une Pull Request

## Licence
Ce projet est sous licence MIT.

---
**Auteur :** Olivier Boutin
