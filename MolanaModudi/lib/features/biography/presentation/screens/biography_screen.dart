import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modudi/features/biography/presentation/providers/biography_provider.dart';
import 'package:modudi/features/biography/presentation/providers/biography_state.dart';
import 'package:modudi/features/biography/domain/entities/biography_event_entity.dart';
import 'package:modudi/core/themes/app_color.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class BiographyScreen extends ConsumerStatefulWidget {
  const BiographyScreen({super.key});

  @override
  ConsumerState<BiographyScreen> createState() => _BiographyScreenState();
}

class _BiographyScreenState extends ConsumerState<BiographyScreen> {
  late ScrollController _scrollController;
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_showAppBarTitle) {
      setState(() => _showAppBarTitle = true);
    } else if (_scrollController.offset <= 200 && _showAppBarTitle) {
      setState(() => _showAppBarTitle = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final biographyState = ref.watch(biographyNotifierProvider);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;

    // Theme-aware colors
    final backgroundColor = isDark 
        ? AppColor.backgroundDark 
        : isSepia 
            ? AppColor.backgroundSepia 
            : AppColor.background;

    final primaryColor = isDark
        ? AppColor.primaryDark
        : isSepia
            ? AppColor.primarySepia
            : AppColor.primary;

    final appBarTextColor = isDark
        ? AppColor.textOnPrimaryDark
        : isSepia
            ? AppColor.textOnPrimarySepia
            : Colors.white;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Modern App Bar with theme-aware styling
            SliverAppBar(
              expandedHeight: 300,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: primaryColor,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: appBarTextColor),
                onPressed: () => context.go('/home'),
              ),
              title: AnimatedOpacity(
                opacity: _showAppBarTitle ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Text(
                  'Sayyid Abul A\'la Maududi',
                  style: TextStyle(
                    color: appBarTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryColor,
                        primaryColor.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: _buildHeroSection(context),
                ),
              ),
            ),

            // Content with proper theme-aware background
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    _buildQuickFacts(context),
                    const SizedBox(height: 40),
                    _buildLifeCycle(context),
                    const SizedBox(height: 40),
                    _buildPhilosophyGoals(context),
                    const SizedBox(height: 40),
                    _buildMajorWorks(context),
                    const SizedBox(height: 40),
                    _buildIntellectualContributions(context),
                    const SizedBox(height: 40),
                    _buildPoliticalThought(context),
                    const SizedBox(height: 40),
                    _buildTimeline(context, biographyState),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;

    final heroTextColor = isDark
        ? AppColor.textOnPrimaryDark
        : isSepia
            ? AppColor.textOnPrimarySepia
            : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Profile Image with theme-aware styling
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/maulana_maududi.jpg',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          heroTextColor.withValues(alpha: 0.2),
                          heroTextColor.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.account_circle_outlined,
                      size: 60,
                      color: heroTextColor.withValues(alpha: 0.9),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Name with enhanced typography
          Text(
            'Sayyid Abul A\'la Maududi',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: heroTextColor,
              height: 1.2,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Title with theme-aware styling
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: heroTextColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: heroTextColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              'Islamic Scholar, Theologian & Political Thinker',
              style: TextStyle(
                fontSize: 14,
                color: heroTextColor.withValues(alpha: 0.95),
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFacts(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;

    final textColor = isDark
        ? AppColor.textPrimaryDark
        : isSepia
            ? AppColor.textPrimarySepia
            : AppColor.textPrimary;

    final secondaryTextColor = isDark
        ? AppColor.textSecondaryDark
        : isSepia
            ? AppColor.textSecondarySepia
            : AppColor.textSecondary;

    final cardColor = isDark
        ? AppColor.surfaceDark
        : isSepia
            ? AppColor.surfaceSepia
            : AppColor.surface;

    final primaryColor = isDark
        ? AppColor.primaryDark
        : isSepia
            ? AppColor.primarySepia
            : AppColor.primary;

    final facts = [
      {
        'icon': Icons.person_outline_rounded,
        'title': 'Full Name',
        'value': 'Sayyid Abul A\'la Maududi',
        'subtitle': 'ابو الاعلیٰ المودودی (Urdu)',
      },
      {
        'icon': Icons.calendar_today_outlined,
        'title': 'Born',
        'value': 'September 25, 1903',
        'subtitle': 'Aurangabad, Hyderabad State',
      },
      {
        'icon': Icons.event_outlined,
        'title': 'Died',
        'value': 'September 22, 1979',
        'subtitle': 'Buffalo, New York, United States',
      },
      {
        'icon': Icons.family_restroom_outlined,
        'title': 'Ancestry',
        'value': 'Descendant of Prophet Muhammad',
        'subtitle': 'Through Chishti Sufi lineage',
      },
      {
        'icon': Icons.school_outlined,
        'title': 'Education',
        'value': 'Traditional Islamic & Modern Studies',
        'subtitle': 'Aligarh, Deoband influences',
      },
      {
        'icon': Icons.language_outlined,
        'title': 'Languages Mastered',
        'value': '7 Languages',
        'subtitle': 'Urdu, Arabic, Persian, English, Hindi, Bengali, German',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Facts',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          
          ...facts.asMap().entries.map((entry) {
            final index = entry.key;
            final fact = entry.value;
            
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : isSepia
                                ? primaryColor.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                        width: 1,
                      ),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            fact['icon'] as IconData,
                            color: primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fact['title'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryTextColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                fact['value'] as String,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              if (fact['subtitle'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  fact['subtitle'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: secondaryTextColor.withValues(alpha: 0.8),
                                    height: 1.3,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLifeCycle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;

    final textColor = isDark
        ? AppColor.textPrimaryDark
        : isSepia
            ? AppColor.textPrimarySepia
            : AppColor.textPrimary;

    final secondaryTextColor = isDark
        ? AppColor.textSecondaryDark
        : isSepia
            ? AppColor.textSecondarySepia
            : AppColor.textSecondary;

    final cardColor = isDark
        ? AppColor.surfaceDark
        : isSepia
            ? AppColor.surfaceSepia
            : AppColor.surface;

    final primaryColor = isDark
        ? AppColor.primaryDark
        : isSepia
            ? AppColor.primarySepia
            : AppColor.primary;

    final sections = [
      {
        'title': 'Early Years (1903-1918)',
        'description': 'Born September 25, 1903, in Aurangabad, Hyderabad State. Son of Ahmad Hasan, a lawyer descended from Chishti Sufi saints. Received traditional Islamic education alongside modern English schooling. Lost father at age 15, forcing early independence and responsibility that shaped his character.',
        'icon': Icons.child_care_outlined,
      },
      {
        'title': 'Educational Foundation (1918-1925)',
        'description': 'Self-taught in Arabic, Persian, English, and German. Studied Islamic jurisprudence, philosophy, and modern political thought. Influenced by Aligarh movement and Deoband seminary traditions, developing a unique synthesis of classical Islamic and contemporary learning.',
        'icon': Icons.school_outlined,
      },
      {
        'title': 'Journalistic Career (1925-1937)',
        'description': 'Started as journalist with "Taj" newspaper in Jabalpur. Editor of "Muslim" in Delhi (1921-1923). Founded "Tarjuman al-Quran" magazine in 1932, which became his primary platform for Islamic thought and social commentary for 47 years until his death.',
        'icon': Icons.edit_outlined,
      },
      {
        'title': 'Intellectual Awakening (1937-1941)',
        'description': 'Developed comprehensive Islamic ideology covering politics, economics, and social reform. Wrote foundational works on Islamic state theory, economic system, and educational philosophy. Began systematic Quranic commentary project that would become his life\'s work.',
        'icon': Icons.lightbulb_outlined,
      },
      {
        'title': 'Jamaat-e-Islami Era (1941-1972)',
        'description': 'Founded Jamaat-e-Islami on August 26, 1941, with 75 founding members. Served as Amir (leader) for 31 years. Established organizational structure, training programs, and systematic approach to Islamic revival and social transformation across South Asia.',
        'icon': Icons.groups_outlined,
      },
      {
        'title': 'Political Struggle (1947-1960s)',
        'description': 'Initially opposed partition but accepted Pakistan. Imprisoned multiple times for political activities. Advocated for Islamic constitution and legal system. Key figure in 1953 anti-Ahmadiyya movement and constitutional debates that shaped modern Pakistan.',
        'icon': Icons.account_balance_outlined,
      },
      {
        'title': 'Literary Pinnacle (1950s-1970s)',
        'description': 'Completed major volumes of Tafhim al-Quran, his comprehensive Quranic commentary. Authored over 120 books and thousands of articles. His works translated into over 40 languages, establishing him as one of the most influential Islamic thinkers of the 20th century.',
        'icon': Icons.menu_book_outlined,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Life Journey',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          
          ...sections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;
            
            return AnimationConfiguration.staggeredList(
              position: index + 10,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : isSepia
                                ? primaryColor.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                        width: 1,
                      ),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            section['icon'] as IconData,
                            color: primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section['title'] as String,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                section['description'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: secondaryTextColor,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPhilosophyGoals(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;

    final textColor = isDark
        ? AppColor.textPrimaryDark
        : isSepia
            ? AppColor.textPrimarySepia
            : AppColor.textPrimary;

    final secondaryTextColor = isDark
        ? AppColor.textSecondaryDark
        : isSepia
            ? AppColor.textSecondarySepia
            : AppColor.textSecondary;

    final cardColor = isDark
        ? AppColor.surfaceDark
        : isSepia
            ? AppColor.surfaceSepia
            : AppColor.surface;

    final primaryColor = isDark
        ? AppColor.primaryDark
        : isSepia
            ? AppColor.primarySepia
            : AppColor.primary;

    final philosophies = [
      {
        'title': 'Islamic Revival',
        'description': 'Comprehensive revival of Islamic civilization through return to Quranic principles and Prophetic traditions in all aspects of life.',
        'icon': Icons.refresh_outlined,
      },
      {
        'title': 'Political Islam',
        'description': 'Establishment of Islamic state based on divine sovereignty, consultation (Shura), and implementation of Islamic law (Shariah).',
        'icon': Icons.account_balance_outlined,
      },
      {
        'title': 'Economic Justice',
        'description': 'Islamic economic system eliminating exploitation, interest (Riba), and ensuring equitable distribution of wealth according to divine guidance.',
        'icon': Icons.balance_outlined,
      },
      {
        'title': 'Educational Reform',
        'description': 'Integration of religious and secular education to produce morally conscious and intellectually capable Muslim leadership.',
        'icon': Icons.school_outlined,
      },
      {
        'title': 'Social Transformation',
        'description': 'Gradual transformation of society through individual reform, collective action, and systematic implementation of Islamic values.',
        'icon': Icons.people_outline,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Philosophy & Goals',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          
          ...philosophies.asMap().entries.map((entry) {
            final index = entry.key;
            final philosophy = entry.value;
            
            return AnimationConfiguration.staggeredList(
              position: index + 15,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : isSepia
                                ? primaryColor.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                        width: 1,
                      ),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            philosophy['icon'] as IconData,
                            color: primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                philosophy['title'] as String,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                philosophy['description'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: secondaryTextColor,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMajorWorks(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;

    final textColor = isDark
        ? AppColor.textPrimaryDark
        : isSepia
            ? AppColor.textPrimarySepia
            : AppColor.textPrimary;

    final secondaryTextColor = isDark
        ? AppColor.textSecondaryDark
        : isSepia
            ? AppColor.textSecondarySepia
            : AppColor.textSecondary;

    final cardColor = isDark
        ? AppColor.surfaceDark
        : isSepia
            ? AppColor.surfaceSepia
            : AppColor.surface;

    final primaryColor = isDark
        ? AppColor.primaryDark
        : isSepia
            ? AppColor.primarySepia
            : AppColor.primary;

    final works = [
      {
        'title': 'Tafhim al-Quran',
        'subtitle': 'Understanding the Quran',
        'description': '6-volume comprehensive commentary covering entire Quran with contemporary relevance and practical guidance for modern Muslims.',
        'icon': Icons.menu_book_outlined,
      },
      {
        'title': 'Towards Understanding Islam',
        'subtitle': 'Risala Diniyat',
        'description': 'Foundational introduction to Islamic faith, translated into over 40 languages and considered essential reading for understanding Islam.',
        'icon': Icons.auto_stories_outlined,
      },
      {
        'title': 'Islamic Way of Life',
        'subtitle': 'Islam ka Nizam-e-Hayat',
        'description': 'Comprehensive exposition of Islamic social, political, and economic systems as alternatives to Western ideologies.',
        'icon': Icons.psychology_outlined,
      },
      {
        'title': 'The Rights of Women in Islam',
        'subtitle': 'Purdah aur Islam mein Aurat ka Maqam',
        'description': 'Detailed analysis of women\'s status, rights, and responsibilities in Islamic society with responses to modern challenges.',
        'icon': Icons.groups_outlined,
      },
      {
        'title': 'Economic System of Islam',
        'subtitle': 'Islam ka Iqtisadi Nizam',
        'description': 'Systematic presentation of Islamic economic principles including prohibition of interest and equitable wealth distribution.',
        'icon': Icons.account_balance_wallet_outlined,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Major Works',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          
          ...works.asMap().entries.map((entry) {
            final index = entry.key;
            final work = entry.value;
            
            return AnimationConfiguration.staggeredList(
              position: index + 20,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : isSepia
                                ? primaryColor.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                        width: 1,
                      ),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            work['icon'] as IconData,
                            color: primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                work['title'] as String,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                work['subtitle'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: primaryColor,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                work['description'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: secondaryTextColor,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildIntellectualContributions(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;

    final textColor = isDark
        ? AppColor.textPrimaryDark
        : isSepia
            ? AppColor.textPrimarySepia
            : AppColor.textPrimary;

    final secondaryTextColor = isDark
        ? AppColor.textSecondaryDark
        : isSepia
            ? AppColor.textSecondarySepia
            : AppColor.textSecondary;

    final cardColor = isDark
        ? AppColor.surfaceDark
        : isSepia
            ? AppColor.surfaceSepia
            : AppColor.surface;

    final primaryColor = isDark
        ? AppColor.primaryDark
        : isSepia
            ? AppColor.primarySepia
            : AppColor.primary;

    final contributions = [
      {
        'title': 'Quranic Exegesis Revolution',
        'description': 'Transformed traditional Quranic commentary by addressing contemporary issues and making divine guidance relevant to modern challenges and scientific developments.',
        'icon': Icons.auto_fix_high_outlined,
      },
      {
        'title': 'Islamic Political Theory',
        'description': 'Developed comprehensive framework for Islamic governance integrating classical principles with modern administrative and constitutional structures.',
        'icon': Icons.account_balance_outlined,
      },
      {
        'title': 'Educational Philosophy',
        'description': 'Pioneered integration of religious and secular knowledge, emphasizing moral development alongside intellectual growth for holistic human development.',
        'icon': Icons.school_outlined,
      },
      {
        'title': 'Comparative Religion Studies',
        'description': 'Conducted systematic analysis of major world religions, ideologies, and philosophical systems from Islamic perspective with scholarly objectivity.',
        'icon': Icons.compare_outlined,
      },
      {
        'title': 'Literary Excellence',
        'description': 'Mastery of multiple languages enabled clear communication of complex theological concepts to diverse audiences across linguistic barriers.',
        'icon': Icons.translate_outlined,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Intellectual Contributions',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          
          ...contributions.asMap().entries.map((entry) {
            final index = entry.key;
            final contribution = entry.value;
            
            return AnimationConfiguration.staggeredList(
              position: index + 25,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : isSepia
                                ? primaryColor.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                        width: 1,
                      ),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                contribution['icon'] as IconData,
                                color: primaryColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Text(
                                contribution['title'] as String,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          contribution['description'] as String,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: secondaryTextColor,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPoliticalThought(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;

    final textColor = isDark
        ? AppColor.textPrimaryDark
        : isSepia
            ? AppColor.textPrimarySepia
            : AppColor.textPrimary;

    final secondaryTextColor = isDark
        ? AppColor.textSecondaryDark
        : isSepia
            ? AppColor.textSecondarySepia
            : AppColor.textSecondary;

    final cardColor = isDark
        ? AppColor.surfaceDark
        : isSepia
            ? AppColor.surfaceSepia
            : AppColor.surface;

    final primaryColor = isDark
        ? AppColor.primaryDark
        : isSepia
            ? AppColor.primarySepia
            : AppColor.primary;

    final thoughts = [
      {
        'title': 'Divine Sovereignty',
        'description': 'Ultimate authority belongs to Allah; human governments must operate within divine guidance and moral framework established by Islamic law.',
        'icon': Icons.gavel_outlined,
      },
      {
        'title': 'Consultation (Shura)',
        'description': 'Democratic consultation among qualified individuals for governance decisions, ensuring representation while maintaining Islamic principles.',
        'icon': Icons.forum_outlined,
      },
      {
        'title': 'Justice and Equality',
        'description': 'Equal treatment under law regardless of social status, with special protection for minorities and emphasis on social justice.',
        'icon': Icons.balance_outlined,
      },
      {
        'title': 'Gradual Implementation',
        'description': 'Step-by-step transformation through education, moral development, and voluntary adoption rather than forced imposition.',
        'icon': Icons.trending_up_outlined,
      },
      {
        'title': 'International Relations',
        'description': 'Peaceful coexistence with non-Muslim nations based on mutual respect, justice, and fulfillment of treaties and agreements.',
        'icon': Icons.public_outlined,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Political Thought',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          
          ...thoughts.asMap().entries.map((entry) {
            final index = entry.key;
            final thought = entry.value;
            
            return AnimationConfiguration.staggeredList(
              position: index + 28,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : isSepia
                                ? primaryColor.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                        width: 1,
                      ),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            thought['icon'] as IconData,
                            color: primaryColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                thought['title'] as String,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                thought['description'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: secondaryTextColor,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, BiographyState biographyState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;

    final textColor = isDark
        ? AppColor.textPrimaryDark
        : isSepia
            ? AppColor.textPrimarySepia
            : AppColor.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildTimelineContent(context, biographyState),
        ],
      ),
    );
  }

  Widget _buildTimelineContent(BuildContext context, BiographyState biographyState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;

    final primaryColor = isDark
        ? AppColor.primaryDark
        : isSepia
            ? AppColor.primarySepia
            : AppColor.primary;

    final cardColor = isDark
        ? AppColor.surfaceDark
        : isSepia
            ? AppColor.surfaceSepia
            : AppColor.surface;

    final textColor = isDark
        ? AppColor.textPrimaryDark
        : isSepia
            ? AppColor.textPrimarySepia
            : AppColor.textPrimary;

    final secondaryTextColor = isDark
        ? AppColor.textSecondaryDark
        : isSepia
            ? AppColor.textSecondarySepia
            : AppColor.textSecondary;

    if (biographyState.status == BiographyStatus.loading) {
      return Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }
    
    if (biographyState.status == BiographyStatus.error) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Error loading timeline: ${biographyState.errorMessage}',
          style: TextStyle(color: Colors.red),
        ),
      );
    }
  
    final keyEvents = biographyState.events.take(5).toList();
    return Column(
      children: keyEvents.asMap().entries.map((entry) {
        final index = entry.key;
        final event = entry.value;
        final isLast = index == keyEvents.length - 1;
        
        return AnimationConfiguration.staggeredList(
          position: index + 30,
          duration: const Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Timeline indicator
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 60,
                            color: primaryColor.withValues(alpha: 0.3),
                          ),
                      ],
                    ),
                    const SizedBox(width: 20),
                
                    // Event content
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : isSepia
                                    ? primaryColor.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.04),
                            width: 1,
                          ),
                          boxShadow: isDark ? [] : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.date,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (event.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                event.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: secondaryTextColor,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
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
      }).toList(),
    );
  }
}