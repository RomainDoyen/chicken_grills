import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chicken_grills/theme/app_theme.dart';
import 'package:chicken_grills/components/action_button.dart';
import 'package:chicken_grills/components/settings_section.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'fr';
  bool _autoBackupEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _notificationsEnabled = data['notificationsEnabled'] ?? true;
            _darkModeEnabled = data['darkModeEnabled'] ?? false;
            _language = data['language'] ?? 'fr';
            _autoBackupEnabled = data['autoBackupEnabled'] ?? true;
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des paramètres: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
              'notificationsEnabled': _notificationsEnabled,
              'darkModeEnabled': _darkModeEnabled,
              'language': _language,
              'autoBackupEnabled': _autoBackupEnabled,
              'settingsUpdatedAt': Timestamp.now(),
            });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paramètres sauvegardés avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde des paramètres'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        title: Text('Paramètres'),
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _saveSettings,
              tooltip: 'Sauvegarder',
            ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryOrange),
              )
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(),
                    SizedBox(height: 24),
                    _buildNotificationSection(),
                    SizedBox(height: 24),
                    _buildAppearanceSection(),
                    SizedBox(height: 24),
                    _buildDataSection(),
                    SizedBox(height: 24),
                    _buildSecuritySection(),
                    SizedBox(height: 24),
                    _buildAboutSection(),
                  ],
                ),
              ),
    );
  }

  Widget _buildProfileSection() {
    return _buildSection(
      title: 'Profil administrateur',
      icon: Icons.admin_panel_settings,
      children: [_buildProfileCard()],
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(0xFFEF5829),
          child: Icon(Icons.admin_panel_settings, color: Colors.white),
        ),
        title: Text('Administrateur'),
        subtitle: Text('Gestionnaire principal'),
        trailing: Icon(Icons.edit),
        onTap: () {
          // Navigation vers l'édition du profil
        },
      ),
    );
  }

  Widget _buildNotificationSection() {
    return _buildSection(
      title: 'Notifications',
      icon: Icons.notifications,
      children: [
        SwitchListTile(
          title: Text('Notifications push'),
          subtitle: Text('Recevoir des notifications sur votre appareil'),
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() {
              _notificationsEnabled = value;
            });
          },
          secondary: Icon(Icons.notifications),
        ),
        ListTile(
          title: Text('Types de notifications'),
          subtitle: Text('Configurer les types de notifications'),
          leading: Icon(Icons.settings),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showNotificationTypesDialog();
          },
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return _buildSection(
      title: 'Apparence',
      icon: Icons.palette,
      children: [
        SwitchListTile(
          title: Text('Mode sombre'),
          subtitle: Text('Activer le thème sombre'),
          value: _darkModeEnabled,
          onChanged: (value) {
            setState(() {
              _darkModeEnabled = value;
            });
          },
          secondary: Icon(Icons.dark_mode),
        ),
        ListTile(
          title: Text('Langue'),
          subtitle: Text(_getLanguageLabel(_language)),
          leading: Icon(Icons.language),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showLanguageDialog();
          },
        ),
      ],
    );
  }

  Widget _buildDataSection() {
    return _buildSection(
      title: 'Données et sauvegarde',
      icon: Icons.backup,
      children: [
        SwitchListTile(
          title: Text('Sauvegarde automatique'),
          subtitle: Text('Sauvegarder automatiquement les données'),
          value: _autoBackupEnabled,
          onChanged: (value) {
            setState(() {
              _autoBackupEnabled = value;
            });
          },
          secondary: Icon(Icons.backup),
        ),
        ListTile(
          title: Text('Exporter les données'),
          subtitle: Text('Télécharger une copie de vos données'),
          leading: Icon(Icons.download),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showExportDialog();
          },
        ),
        ListTile(
          title: Text('Importer des données'),
          subtitle: Text('Restaurer des données depuis un fichier'),
          leading: Icon(Icons.upload),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showImportDialog();
          },
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return _buildSection(
      title: 'Sécurité',
      icon: Icons.security,
      children: [
        ListTile(
          title: Text('Changer le mot de passe'),
          subtitle: Text('Modifier votre mot de passe'),
          leading: Icon(Icons.lock),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showChangePasswordDialog();
          },
        ),
        ListTile(
          title: Text('Authentification à deux facteurs'),
          subtitle: Text('Activer la sécurité renforcée'),
          leading: Icon(Icons.verified_user),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showTwoFactorDialog();
          },
        ),
        ListTile(
          title: Text('Sessions actives'),
          subtitle: Text('Gérer les connexions actives'),
          leading: Icon(Icons.devices),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showActiveSessionsDialog();
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'À propos',
      icon: Icons.info,
      children: [
        ListTile(
          title: Text('Version de l\'application'),
          subtitle: Text('1.0.0'),
          leading: Icon(Icons.info),
        ),
        ListTile(
          title: Text('Conditions d\'utilisation'),
          subtitle: Text('Lire les conditions d\'utilisation'),
          leading: Icon(Icons.description),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showTermsDialog();
          },
        ),
        ListTile(
          title: Text('Politique de confidentialité'),
          subtitle: Text('Lire la politique de confidentialité'),
          leading: Icon(Icons.privacy_tip),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showPrivacyDialog();
          },
        ),
        ListTile(
          title: Text('Contacter le support'),
          subtitle: Text('Obtenir de l\'aide'),
          leading: Icon(Icons.support_agent),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            _showSupportDialog();
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFFEF5829), size: 24),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Card(child: Column(children: children)),
      ],
    );
  }

  String _getLanguageLabel(String language) {
    switch (language) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      default:
        return 'Français';
    }
  }

  void _showNotificationTypesDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Types de notifications'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: Text('Nouveaux utilisateurs'),
                  value: true,
                  onChanged: (value) {},
                ),
                CheckboxListTile(
                  title: Text('Nouveaux marqueurs'),
                  value: true,
                  onChanged: (value) {},
                ),
                CheckboxListTile(
                  title: Text('Erreurs système'),
                  value: true,
                  onChanged: (value) {},
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _showLanguageDialog() {
    String selectedLanguage = _language;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Choisir la langue'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: Text('Français'),
                  value: 'fr',
                  groupValue: selectedLanguage,
                  onChanged: (value) {
                    selectedLanguage = value!;
                  },
                ),
                RadioListTile<String>(
                  title: Text('English'),
                  value: 'en',
                  groupValue: selectedLanguage,
                  onChanged: (value) {
                    selectedLanguage = value!;
                  },
                ),
                RadioListTile<String>(
                  title: Text('Español'),
                  value: 'es',
                  groupValue: selectedLanguage,
                  onChanged: (value) {
                    selectedLanguage = value!;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _language = selectedLanguage;
                  });
                  Navigator.of(context).pop();
                },
                child: Text('Confirmer'),
              ),
            ],
          ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Exporter les données'),
            content: Text(
              'Cette fonctionnalité sera disponible prochainement.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Importer des données'),
            content: Text(
              'Cette fonctionnalité sera disponible prochainement.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Changer le mot de passe'),
            content: Text(
              'Cette fonctionnalité sera disponible prochainement.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showTwoFactorDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Authentification à deux facteurs'),
            content: Text(
              'Cette fonctionnalité sera disponible prochainement.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showActiveSessionsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Sessions actives'),
            content: Text(
              'Cette fonctionnalité sera disponible prochainement.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Conditions d\'utilisation'),
            content: Text(
              'Les conditions d\'utilisation seront disponibles prochainement.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Politique de confidentialité'),
            content: Text(
              'La politique de confidentialité sera disponible prochainement.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Contacter le support'),
            content: Text(
              'Pour contacter le support, envoyez un email à support@chicken-grills.com',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Fermer'),
              ),
            ],
          ),
    );
  }
}
