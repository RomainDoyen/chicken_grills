import 'package:chicken_grills/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundPeach,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return const _GuestAccountView();
          }

          return _AuthenticatedAccountView(user: user);
        },
      ),
    );
  }
}

class _GuestAccountView extends StatelessWidget {
  const _GuestAccountView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: AppTheme.primaryOrange),
            const SizedBox(height: 24),
            const Text(
              'Espace réservé aux professionnels',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Cette section permet aux professionnels partenaires de gérer leurs informations et leurs points de vente. Si vous représentez un établissement, créez votre compte pro pour rejoindre le réseau Chicken Grills.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 32),
            AppTheme.primaryButton(
              text: 'Connexion',
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
            const SizedBox(height: 16),
            AppTheme.secondaryButton(
              text: 'Créer un compte',
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthenticatedAccountView extends StatelessWidget {
  const _AuthenticatedAccountView({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.data();
        final String role = data?['role'] ?? 'lambda';
        final String firstName = data?['firstName'] ?? '';
        final String lastName = data?['lastName'] ?? '';

        final bool isAdmin = role == 'admin';
        final bool isPro = role == 'pro';

        if (!isAdmin && !isPro) {
          return _UnauthorizedAccountView(email: user.email ?? '');
        }

        final Widget primaryAction =
            isAdmin
                ? AppTheme.primaryButton(
                    text: 'Accéder à l’administration',
                    onPressed: () {
                      Navigator.pushNamed(context, '/admin_home');
                    },
                  )
                : AppTheme.primaryButton(
                    text: 'Gérer mes marqueurs',
                    onPressed: () {
                      Navigator.pushNamed(context, '/pro_home');
                    },
                  );

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.secondaryOrange,
                        child: Text(
                          _initials(firstName, lastName),
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstName.isNotEmpty || lastName.isNotEmpty
                                  ? '$firstName $lastName'
                                  : user.email ?? '',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAdmin ? 'Compte administrateur' : 'Compte professionnel',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (user.email != null) ...[
                    const SizedBox(height: 16),
                    _InfoRow(icon: Icons.email_outlined, text: user.email!),
                  ],
                  if (data?['numTel'] != null && (data?['numTel'] as String).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.phone_outlined, text: data?['numTel']),
                  ],
                  if (data?['numSiret'] != null && (data?['numSiret'] as String).isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.business_center_outlined, text: 'SIRET ${data?['numSiret']}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            primaryAction,
            const SizedBox(height: 16),
            AppTheme.secondaryButton(
              text: 'Déconnexion',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Déconnexion réussie.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  String _initials(String firstName, String lastName) {
    final String first = firstName.isNotEmpty ? firstName[0] : '';
    final String last = lastName.isNotEmpty ? lastName[0] : '';
    final String fallback = (user.email != null && user.email!.isNotEmpty)
        ? user.email!.substring(0, 1)
        : '?';
    final String combined = (first + last).trim();
    return combined.isNotEmpty ? combined.toUpperCase() : fallback.toUpperCase();
  }
}

class _UnauthorizedAccountView extends StatelessWidget {
  const _UnauthorizedAccountView({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 60, color: AppTheme.primaryOrange),
            const SizedBox(height: 20),
            Text(
              'Cet espace est réservé aux professionnels.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              email.isNotEmpty
                  ? "Le compte $email ne dispose pas d’un accès professionnel. Contactez l’équipe Chicken Grills pour transformer votre accès."
                  : "Connectez-vous avec un compte professionnel ou contactez-nous pour devenir partenaire.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),
            AppTheme.secondaryButton(
              text: 'Déconnexion',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Déconnexion réussie.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryOrange),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

