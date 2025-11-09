import 'package:chicken_grills/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutTab extends StatefulWidget {
  const AboutTab({super.key});

  @override
  State<AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<AboutTab> {
  bool _termsExpanded = false;
  bool _privacyExpanded = false;
  bool _faqExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundPeach,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.info_outline,
                      color: AppTheme.primaryOrange, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'À propos',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      const _StaticTile(
                        icon: Icons.info,
                        title: 'Version de l\'application',
                        subtitle: '1.0.0',
                      ),
                      const Divider(height: 1),
                      _ExpandableTile(
                        icon: Icons.article_outlined,
                        title: 'Conditions d\'utilisation',
                        isExpanded: _termsExpanded,
                        onToggle: () {
                          setState(() {
                            _termsExpanded = !_termsExpanded;
                          });
                        },
                        children: _termsContent,
                      ),
                      const Divider(height: 1),
                      _ExpandableTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Politique de confidentialité',
                        isExpanded: _privacyExpanded,
                        onToggle: () {
                          setState(() {
                            _privacyExpanded = !_privacyExpanded;
                          });
                        },
                        children: _privacyContent,
                      ),
                      const Divider(height: 1),
                      const _StaticTile(
                        icon: Icons.support_agent,
                        title: 'Contacter le support',
                        subtitle:
                            'Support Chicken Grills — support@chicken-grills.com',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Liens utiles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Rejoignez la communauté Chicken Grills et restez informé(e) des nouveautés.',
                        style: TextStyle(height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: const [
                          _LinkButton(
                            icon: Icons.facebook,
                            label: 'Facebook',
                            url: 'https://www.facebook.com/chickengrills',
                          ),
                          _LinkButton(
                            icon: Icons.camera_alt_outlined,
                            label: 'Instagram',
                            url: 'https://www.instagram.com/chickengrills',
                          ),
                          _LinkButton(
                            icon: Icons.business_center,
                            label: 'LinkedIn',
                            url: 'https://www.linkedin.com/company/chickengrills',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ExpandableTile(
                        icon: Icons.help_outline,
                        title: 'FAQ Chicken Grills',
                        isExpanded: _faqExpanded,
                        onToggle: () {
                          setState(() {
                            _faqExpanded = !_faqExpanded;
                          });
                        },
                        children: const [
                          _Paragraph(
                            title: 'Questions fréquentes',
                            body:
                                'Retrouvez les réponses sur la validation des établissements, la gestion des marqueurs et les bonnes pratiques pour mettre à jour vos informations.',
                          ),
                          SizedBox(height: 8),
                          _LinkButton(
                            icon: Icons.menu_book,
                            label: 'Consulter la FAQ complète',
                            url: 'https://exemple.chicken-grills.com/faq',
                            isFullWidth: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Devenir partenaire',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Vous souhaitez référencer votre établissement ? Consultez la procédure d\'adhésion et envoyez-nous votre demande.',
                        style: TextStyle(height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      const _LinkButton(
                        icon: Icons.playlist_add_check,
                        label: 'Procédure d\'adhésion',
                        url: 'https://exemple.chicken-grills.com/devenir-partenaire',
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> get _termsContent => const [
        _Paragraph(
          title: '1. Objet',
          body:
              'Les présentes conditions d\'utilisation encadrent l\'accès à l\'application Chicken Grills et l\'usage des services destinés aux utilisateurs finaux et aux professionnels référencés.',
        ),
        _Paragraph(
          title: '2. Création de compte',
          body:
              'L\'inscription nécessite des informations exactes. Pour les comptes professionnels, vous certifiez disposer des autorisations nécessaires pour publier des informations liées à votre établissement.',
        ),
        _Paragraph(
          title: '3. Responsabilité des contenus',
          body:
              'Chaque professionnel est responsable des données qu\'il publie (coordonnées, description, images). Chicken Grills se réserve le droit de modérer ou supprimer tout contenu inapproprié.',
        ),
        _Paragraph(
          title: '4. Utilisation des services',
          body:
              'L\'application doit être utilisée dans le respect de la loi et des présentes conditions. Il est interdit de porter atteinte à la sécurité de la plateforme ou d\'utiliser les données collectées à des fins illégales.',
        ),
        _Paragraph(
          title: '5. Suspension et résiliation',
          body:
              'Chicken Grills peut suspendre ou résilier l\'accès à un compte en cas de non-respect des conditions, de fraude ou d\'activité malveillante.',
        ),
      ];

  List<Widget> get _privacyContent => const [
        _Paragraph(
          title: '1. Collecte des données',
          body:
              'Nous collectons les données fournies lors de l\'inscription (nom, email, téléphone, SIRET, images) ainsi que les informations associées aux marqueurs publiés.',
        ),
        _Paragraph(
          title: '2. Utilisation des données',
          body:
              'Les données permettent de présenter votre établissement aux utilisateurs, d\'assurer le support et d\'améliorer les services. Aucune donnée n\'est vendue à des tiers.',
        ),
        _Paragraph(
          title: '3. Durée de conservation',
          body:
              'Les données sont conservées tant que le compte est actif et supprimées ou anonymisées après fermeture du compte, sauf obligation légale contraire.',
        ),
        _Paragraph(
          title: '4. Droits des utilisateurs',
          body:
              'Vous pouvez demander l\'accès, la rectification ou la suppression de vos données en écrivant à support@chicken-grills.com. Nous répondrons dans les meilleurs délais.',
        ),
        _Paragraph(
          title: '5. Sécurité',
          body:
              'Chicken Grills met en œuvre des mesures techniques et organisationnelles adaptées pour protéger vos données contre l\'accès non autorisé, la perte ou les altérations.',
        ),
      ];
}

class _StaticTile extends StatelessWidget {
  const _StaticTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryOrange),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
    );
  }
}

class _ExpandableTile extends StatelessWidget {
  const _ExpandableTile({
    required this.icon,
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: isExpanded,
        onExpansionChanged: (_) => onToggle(),
        leading: Icon(icon, color: AppTheme.primaryOrange),
        iconColor: AppTheme.primaryOrange,
        collapsedIconColor: AppTheme.primaryOrange,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        childrenPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: children,
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.icon,
    required this.label,
    required this.url,
    this.isFullWidth = false,
  });

  final IconData icon;
  final String label;
  final String url;
  final bool isFullWidth;

  Future<void> _openLink() async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _openLink,
      ),
    );
  }
}

