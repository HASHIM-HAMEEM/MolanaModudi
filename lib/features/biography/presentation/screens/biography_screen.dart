import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:logging/logging.dart';

import '../../../../core/themes/app_color.dart';
import '../../../../routes/route_names.dart';
import '../providers/biography_provider.dart';
import '../providers/biography_state.dart';
import '../../domain/entities/biography_event_entity.dart';

class BiographyScreen extends ConsumerWidget {
  BiographyScreen({super.key});
  
  final _log = Logger('BiographyScreen');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(biographyNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColor.background, // Use the background color from AppColor
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final router = GoRouter.of(context);
            final canPop = router.canPop();
            _log.info('BiographyScreen: canPop() = $canPop');
            if (canPop) {
              router.pop();
            } else {
              _log.info('BiographyScreen: cannot pop, navigating to home.');
              router.go(RouteNames.home); // Fallback to home if cannot pop
            }
          },
        ),
        title: const Text('Biography of Maulana Maududi'),
        backgroundColor: AppColor.primary,
        elevation: 4,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(context, state, ref),
    );
  }

  Widget _buildBody(BuildContext context, BiographyState state, WidgetRef ref) {
    final theme = Theme.of(context);

    switch (state.status) {
      case BiographyStatus.loading:
      case BiographyStatus.initial:
        return Center(child: CircularProgressIndicator(color: AppColor.primary));

      case BiographyStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColor.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load biography',
                  style: theme.textTheme.titleLarge?.copyWith(color: AppColor.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? 'An unknown error occurred.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColor.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => ref.read(biographyNotifierProvider.notifier).fetchBiography(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );

      case BiographyStatus.success:
        if (state.events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_outlined, size: 48, color: AppColor.primary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'No biography events available',
                  style: theme.textTheme.titleLarge?.copyWith(color: AppColor.textPrimary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Create biography data model based on the React template
        final biographyData = _createBiographyData(state.events);
        
        // Use SingleChildScrollView with a Column for the main content
        return SingleChildScrollView(
          child: Column(
            children: [
              // Hero Section
              _buildHeroSection(biographyData),
              
              // Quick Facts Section
              _buildQuickFactsSection(biographyData, theme),
              
              // Biography Sections
              _buildBiographySections(biographyData, theme),
              
              // Timeline Section
              _buildTimelineSection(biographyData, theme),
              
              // Footer
              _buildFooter(theme),
            ],
          ),
        );
    }
  }

  // Create biography data model based on the React template
  Map<String, dynamic> _createBiographyData(List<BiographyEventEntity> events) {
    // Convert timeline events to the format needed for the UI
    final timeline = events.map((event) {
      final yearMatch = RegExp(r'\b(\d{4})\b').firstMatch(event.date);
      final year = yearMatch != null ? yearMatch.group(1) : event.date;
      
      return {
        'year': year,
        'event': '${event.description.split('.').first}.', // First sentence with period
      };
    }).toList();
    
    // Create the biography data model similar to the React template
    return {
      'name': "Sayyid Abul A'la Maududi",
      'title': "Islamic Scholar, Theologian & Political Thinker",
      'imageUrl': "assets/images/maududi.jpg", // Replace with actual image path if available
      'quote': "Revival of Islam is not possible without a revival of Iman in the hearts of Muslims.",
      'quickFacts': [
        { 'label': "Born", 'value': "September 25, 1903", 'icon': Icons.calendar_today },
        { 'label': "Died", 'value': "September 22, 1979 (aged 75)", 'icon': Icons.calendar_today },
        { 'label': "Place of Birth", 'value': "Aurangabad, Hyderabad State, British India", 'icon': Icons.location_on },
        { 'label': "Resting Place", 'value': "Ichhra, Lahore, Pakistan", 'icon': Icons.location_on },
        { 'label': "Primary Focus", 'value': "Islamic Revivalism, Political Islam", 'icon': Icons.star },
        { 'label': "Key Achievement", 'value': "Founder of Jamaat-e-Islami, Author of Tafhim-ul-Quran", 'icon': Icons.emoji_events },
      ],
      'sections': [
        {
          'title': "Early Life & Education",
          'icon': Icons.people,
          'content': [
            "Sayyid Abul A'la Maududi was born in Aurangabad, India, into a family with a strong religious and scholarly tradition. His father, Maulana Ahmad Hasan, was a lawyer and a descendant of the Chishti line of saints.",
            "Maududi received his early education at home, mastering Arabic, Persian, Urdu, and English. He later attended Madrasa Furqania in Aurangabad and Darul Uloom Fatehpur in Delhi. His formal education was supplemented by extensive self-study, particularly in history, philosophy, and political science.",
            "He embarked on his career as a journalist at a young age, contributing to various newspapers and journals, which significantly honed his writing and analytical prowess."
          ],
          'imageUrl': null
        },
        {
          'title': "Intellectual Journey & Ideology",
          'icon': Icons.menu_book,
          'content': [
            "Maududi's intellectual journey was profoundly shaped by a deep concern for the state of Muslims and the Islamic world. He posited that the decline of Muslims stemmed from their deviation from the authentic teachings of Islam.",
            "He was a staunch advocate for the establishment of an Islamic state governed by Sharia law, arguing that Islam offers a comprehensive framework for all aspects of life, encompassing politics and governance.",
            "His ideology underscored Tawhid (oneness of God), the absolute sovereignty of Allah, and the pivotal role of Muslims in establishing a just social order founded on Islamic principles. He was notably critical of both Western secularism and what he perceived as stagnant traditional Muslim scholasticism."
          ],
          'imageUrl': null
        },
        {
          'title': "Establishment of Jamaat-e-Islami",
          'icon': Icons.account_balance,
          'content': [
            "In 1941, Maududi founded Jamaat-e-Islami (JI), an influential Islamic political party and social movement, with the explicit aim of establishing an Islamic state aligned with his vision.",
            "The party initially operated within British India and subsequently in Pakistan following its creation in 1947. JI evolved into a significant force in Pakistani politics, consistently advocating for the Islamization of laws and societal norms.",
            "Maududi served as the Ameer (leader) of Jamaat-e-Islami for numerous years, meticulously guiding its policies and multifaceted activities."
          ],
          'imageUrl': null,
          'imageFirst': true
        },
        {
          'title': "Major Literary Works",
          'icon': Icons.edit,
          'content': [
            "Maulana Maududi was an exceptionally prolific writer, authoring over 120 books and pamphlets, and delivering a vast number of speeches. His extensive writings have been translated into numerous languages worldwide.",
            "His most celebrated work is 'Tafhim-ul-Quran' (Towards Understanding the Quran), a monumental six-volume translation and commentary of the Quran, a scholarly endeavor that spanned 30 years of dedicated effort.",
            "Other seminal works include 'Al Jihad fil Islam' (Jihad in Islam), 'Khilafat o Malukiyat' (Caliphate and Monarchy), 'Islamic Way of Life', and 'Let Us Be Muslims'. These diverse works cover a wide spectrum of topics, including Quranic exegesis, Islamic jurisprudence, political theory, and pressing social issues."
          ],
          'works': [ 
            { 'title': "Tafhim-ul-Quran", 'description': "Comprehensive Quranic commentary and translation." },
            { 'title': "Al Jihad fil Islam", 'description': "An exposition on the concept of Jihad in Islam." },
            { 'title': "Khilafat o Malukiyat", 'description': "A critical analysis of Islamic political history and theory." },
            { 'title': "Islamic Way of Life", 'description': "A concise guide to Islamic principles for daily life." }
          ]
        },
      ],
      'timeline': timeline,
    };
  }

  // Build the hero section with profile image, name, title and quote
  Widget _buildHeroSection(Map<String, dynamic> biographyData) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColor.primary, AppColor.primary.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                biographyData['imageUrl'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColor.primaryLight,
                    child: Center(
                      child: Text(
                        biographyData['name'].toString().substring(0, 1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Name
          Text(
            biographyData['name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Title
          Text(
            biographyData['title'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Quote
          if (biographyData['quote'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColor.primaryLighter, width: 3),
                ),
              ),
              child: Text(
                '"${biographyData['quote']}"',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
                textAlign: TextAlign.left,
              ),
            ),
        ],
      ),
    );
  }

  // Build the quick facts section with info cards
  Widget _buildQuickFactsSection(Map<String, dynamic> biographyData, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      color: AppColor.surfaceVariant,
      child: Column(
        children: [
          Text(
            'At a Glance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColor.primary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // List of quick facts instead of grid to prevent overflow
          AnimationLimiter(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: biographyData['quickFacts'].length,
              itemBuilder: (context, index) {
                final fact = biographyData['quickFacts'][index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildInfoCard(
                          icon: fact['icon'],
                          label: fact['label'],
                          value: fact['value'],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  // Build a single info card for quick facts
  Widget _buildInfoCard({required IconData icon, required String label, required String value}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.primaryLighter,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: AppColor.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColor.textSecondary,
                      height: 1.4,
                    ),
                    // Remove maxLines constraint to show all text
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build the biography sections with cards for each section
  Widget _buildBiographySections(Map<String, dynamic> biographyData, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          // Build each section as a card
          for (int i = 0; i < biographyData['sections'].length; i++) 
            AnimationConfiguration.staggeredList(
              position: i,
              duration: const Duration(milliseconds: 450),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _buildBiographySectionCard(
                      section: biographyData['sections'][i],
                      imageFirst: i % 2 != 0, // Alternate image position
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Build a single biography section card
  Widget _buildBiographySectionCard({required Map<String, dynamic> section, bool imageFirst = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.primaryLighter,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(section['icon'], size: 24, color: AppColor.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section['title'],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Section content with optional image
          if (section['imageUrl'] != null) 
            _buildSectionWithImage(section, imageFirst)
          else
            _buildSectionContent(section['content']),
          
          // Notable works section if available
          if (section['works'] != null) _buildNotableWorks(section['works']),
        ],
      ),
    );
  }
  
  // Build section with image and content
  Widget _buildSectionWithImage(Map<String, dynamic> section, bool imageFirst) {
    final content = _buildSectionContent(section['content']);
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        section['imageUrl'],
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 180,
            width: double.infinity,
            color: AppColor.primaryLighter,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: AppColor.primary,
                size: 40,
              ),
            ),
          );
        },
      ),
    );
    
    return Column(
      children: imageFirst 
        ? [image, const SizedBox(height: 16), content]
        : [content, const SizedBox(height: 16), image],
    );
  }
  
  // Build section content paragraphs
  Widget _buildSectionContent(List<dynamic> contentList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < contentList.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i < contentList.length - 1 ? 12.0 : 0),
            child: Text(
              contentList[i],
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColor.textPrimary,
              ),
            ),
          ),
      ],
    );
  }
  
  // Build notable works list
  Widget _buildNotableWorks(List<dynamic> works) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Notable Works:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColor.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        // Use ListView instead of GridView to prevent overflow
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: works.length,
          itemBuilder: (context, index) {
            final work = works[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColor.primaryLighter,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColor.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      work['title'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      work['description'],
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColor.primary.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Build the timeline section with animated timeline items
  Widget _buildTimelineSection(Map<String, dynamic> biographyData, ThemeData theme) {
    final timeline = biographyData['timeline'] as List<dynamic>;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      color: AppColor.primaryLighter.withOpacity(0.3),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'A Journey Through Time',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColor.primary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          
          // Timeline items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              children: [
                // Vertical line for the timeline
                Positioned(
                  left: 12, // Center of the timeline marker
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: Container(
                    color: AppColor.primary.withOpacity(0.3),
                  ),
                ),
                
                // Timeline items
                Column(
                  children: [
                    for (int i = 0; i < timeline.length; i++)
                      _buildTimelineItem(timeline[i], i),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Build a single timeline item
  Widget _buildTimelineItem(Map<String, dynamic> item, int index) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        horizontalOffset: 50.0,
        child: FadeInAnimation(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline marker
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Timeline content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['year'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColor.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['event'],
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColor.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build the footer section
  Widget _buildFooter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      color: AppColor.primary,
      child: Column(
        children: [
          Text(
            '© ${DateTime.now().year} Maulana Maududi Digital Library',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Designed to honor the life and works of Sayyid Abul A\'la Maududi',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}