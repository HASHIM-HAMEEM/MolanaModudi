import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:modudi/features/settings/presentation/providers/app_settings_provider.dart';
import 'package:modudi/features/splash/presentation/providers/splash_provider.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/themes/app_font_helper.dart';
import '../../../../routes/route_names.dart';
import '../widgets/animated_quote_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  AnimationController? _logoController;
  AnimationController? _textController;
  AnimationController? _progressController;
  AnimationController? _backgroundController;
  
  Animation<double>? _logoScale;
  Animation<double>? _logoOpacity;
  Animation<double>? _textOpacity;
  Animation<double>? _textSlide;
  Animation<double>? _progressOpacity;
  Animation<Color?>? _backgroundGradient;
  
  bool _shouldShowSplash = false;

  // Keys for SharedPreferences
  static const String _firstLaunchKey = 'app_first_launch';
  static const String _lastDataUpdateKey = 'app_last_data_update';
  static const Duration _dataUpdateInterval = Duration(days: 7); // Weekly updates

  @override
  void initState() {
    super.initState();
    _checkIfSplashNeeded();
  }

  void _checkIfSplashNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = !prefs.containsKey(_firstLaunchKey);
    final lastUpdateTimestamp = prefs.getInt(_lastDataUpdateKey) ?? 0;
    final lastUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdateTimestamp);
    final now = DateTime.now();
    final needsWeeklyUpdate = now.difference(lastUpdate) > _dataUpdateInterval;

    if (isFirstLaunch || needsWeeklyUpdate) {
      // Show splash screen and preload data
      setState(() {
        _shouldShowSplash = true;
      });
      _initializeAnimations();
      _startSplashSequence();
      
      // Mark first launch and update timestamp
      if (isFirstLaunch) {
        await prefs.setBool(_firstLaunchKey, true);
      }
      await prefs.setInt(_lastDataUpdateKey, now.millisecondsSinceEpoch);
    } else {
      // Skip splash and go directly to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(RouteNames.home);
        }
      });
    }
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Progress animation controller
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Background animation controller
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Define animations
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController!, curve: Curves.elasticOut),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController!, curve: Curves.easeInOut),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController!, curve: Curves.easeInOut),
    );

    _textSlide = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController!, curve: Curves.easeOutCubic),
    );

    _progressOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController!, curve: Curves.easeInOut),
    );

    _backgroundGradient = ColorTween(
      begin: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
      end: AppTheme.lightTheme.primaryColor.withValues(alpha: 0.3),
    ).animate(CurvedAnimation(parent: _backgroundController!, curve: Curves.easeInOut));
  }

  void _startSplashSequence() async {
    // Start background animation immediately
    _backgroundController?.forward();
    
    // Start logo animation after a brief delay
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController?.forward();

    // Start text animation
    await Future.delayed(const Duration(milliseconds: 800));
    _textController?.forward();

    // Start progress animation
    await Future.delayed(const Duration(milliseconds: 1200));
    _progressController?.forward();

    // Start data preloading
    _startDataPreloading();
  }

  void _startDataPreloading() async {
    final splashNotifier = ref.read(splashProvider.notifier);
    await splashNotifier.preloadEssentialData();
  }

  @override
  void dispose() {
    _logoController?.dispose();
    _textController?.dispose();
    _progressController?.dispose();
    _backgroundController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If not supposed to show splash, show empty widget
    if (!_shouldShowSplash) {
      return const SizedBox.shrink();
    }

    final size = MediaQuery.of(context).size;
    final appSettings = ref.watch(appSettingsProvider);
    final splashState = ref.watch(splashProvider);
    final fontScale = appSettings.fontScale;

    // Listen for completion and navigate
    ref.listen(splashProvider, (previous, next) {
      if (next.isCompleted && mounted) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            context.go(RouteNames.home);
          }
        });
      }
    });

    // If animations are not initialized, show loading
    if (_logoController == null || _textController == null || 
        _progressController == null || _backgroundController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController!,
          _textController!,
          _progressController!,
          _backgroundController!,
        ]),
        builder: (context, child) {
          return Container(
            width: size.width,
            height: size.height,
                         decoration: BoxDecoration(
               gradient: _buildBackgroundGradient(appSettings.themeMode),
             ),
            child: Stack(
              children: [
                // Floating particles background
                _buildFloatingParticles(),
                
                // Main content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      children: [
                        // Top spacing
                        SizedBox(height: size.height * 0.15),
                        
                        // Logo and title section
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                                             // App logo with animation
                               _buildAnimatedLogo(appSettings.themeMode, fontScale),
                               
                               const SizedBox(height: 32),
                               
                               // App title with animation
                               _buildAnimatedTitle(appSettings.themeMode, fontScale),
                               
                               const SizedBox(height: 16),
                               
                               // Subtitle with animation
                               _buildAnimatedSubtitle(appSettings.themeMode, fontScale),
                            ],
                          ),
                        ),
                        
                        // Author section
                        Expanded(
                          flex: 2,
                          child: _buildAuthorSection(appSettings.themeMode, fontScale),
                        ),
                        
                        // Animated quotes section
                        Expanded(
                          flex: 2,
                          child: AnimatedQuoteWidget(
                            theme: appSettings.themeMode,
                            fontScale: fontScale,
                          ),
                        ),
                        
                        // Progress section
                        Expanded(
                          flex: 1,
                          child: _buildProgressSection(splashState, appSettings.themeMode, fontScale),
                        ),
                        
                        // Bottom spacing
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  LinearGradient _buildBackgroundGradient(AppThemeMode theme) {
    switch (theme) {
      case AppThemeMode.light:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.lightTheme.scaffoldBackgroundColor,
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
          ],
        );
      case AppThemeMode.dark:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkTheme.primaryColor.withValues(alpha: 0.2),
            AppTheme.darkTheme.scaffoldBackgroundColor,
            AppTheme.darkTheme.primaryColor.withValues(alpha: 0.1),
          ],
        );
      case AppThemeMode.sepia:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.sepiaTheme.primaryColor.withValues(alpha: 0.15),
            AppTheme.sepiaTheme.scaffoldBackgroundColor,
            AppTheme.sepiaTheme.primaryColor.withValues(alpha: 0.08),
                      ],
          );
      case AppThemeMode.system:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.lightTheme.scaffoldBackgroundColor,
            AppTheme.lightTheme.primaryColor.withValues(alpha: 0.05),
          ],
        );
    }
  }

  Widget _buildFloatingParticles() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _backgroundController!,
        builder: (context, child) {
          return CustomPaint(
            painter: ParticlesPainter(_backgroundController!.value),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedLogo(AppThemeMode theme, double fontScale) {
    return Transform.scale(
      scale: _logoScale?.value ?? 1.0,
      child: Opacity(
        opacity: _logoOpacity?.value ?? 1.0,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _getThemeColor(theme),
                _getThemeColor(theme).withValues(alpha: 0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _getThemeColor(theme).withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.menu_book_rounded,
            size: 60,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle(AppThemeMode theme, double fontScale) {
    return Transform.translate(
      offset: Offset(0, _textSlide?.value ?? 0.0),
      child: Opacity(
        opacity: _textOpacity?.value ?? 1.0,
        child: Text(
          'Molana Moududi',
          style: GoogleFonts.playfairDisplay(
            textStyle: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _getThemeColor(theme),
              letterSpacing: 1.2,
            ).withAppFontScale(fontScale),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAnimatedSubtitle(AppThemeMode theme, double fontScale) {
    return Transform.translate(
      offset: Offset(0, (_textSlide?.value ?? 0.0) * 0.8),
      child: Opacity(
        opacity: (_textOpacity?.value ?? 1.0) * 0.9,
        child: Text(
          'إسلامی فکر و تعلیمات',
          style: GoogleFonts.amiri(
            textStyle: TextStyle(
              fontSize: 20,
              color: _getThemeColor(theme).withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ).withAppFontScale(fontScale),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAuthorSection(AppThemeMode theme, double fontScale) {
    return Opacity(
      opacity: _textOpacity?.value ?? 1.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Author portrait
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getThemeColor(theme).withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getThemeColor(theme).withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/landingpageicon.jpg',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if image fails to load
                  return Container(
                    color: _getThemeColor(theme).withValues(alpha: 0.1),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: _getThemeColor(theme).withValues(alpha: 0.6),
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Author name
          Text(
            'Sayyid Abul A\'la Maududi',
            style: GoogleFonts.playfairDisplay(
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _getThemeColor(theme),
              ).withAppFontScale(fontScale),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Author description
          Text(
            'مفکر، مصنف اور اسلامی تحریک کے بانی',
            style: GoogleFonts.amiri(
              textStyle: TextStyle(
                fontSize: 14,
                color: _getThemeColor(theme).withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ).withAppFontScale(fontScale),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(SplashState splashState, AppThemeMode theme, double fontScale) {
    return Opacity(
      opacity: _progressOpacity?.value ?? 1.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress text
          Text(
            splashState.currentTask.isEmpty ? 'لوڈ ہو رہا ہے...' : splashState.currentTask,
            style: GoogleFonts.notoSansArabic(
              textStyle: TextStyle(
                fontSize: 14,
                color: _getThemeColor(theme).withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ).withAppFontScale(fontScale),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Progress bar
          Container(
            width: 200,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: _getThemeColor(theme).withValues(alpha: 0.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: splashState.progress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(_getThemeColor(theme)),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Progress percentage
          Text(
            '${(splashState.progress * 100).toInt()}%',
            style: GoogleFonts.poppins(
              textStyle: TextStyle(
                fontSize: 12,
                color: _getThemeColor(theme).withValues(alpha: 0.6),
                fontWeight: FontWeight.w400,
              ).withAppFontScale(fontScale),
            ),
          ),
        ],
      ),
    );
  }

  Color _getThemeColor(AppThemeMode theme) {
    switch (theme) {
      case AppThemeMode.light:
        return AppTheme.lightTheme.primaryColor;
      case AppThemeMode.dark:
        return AppTheme.darkTheme.primaryColor;
      case AppThemeMode.sepia:
        return AppTheme.sepiaTheme.primaryColor;
      case AppThemeMode.system:
        return AppTheme.lightTheme.primaryColor; // Default to light
    }
  }
}

// Custom painter for floating particles
class ParticlesPainter extends CustomPainter {
  final double animationValue;

  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 20; i++) {
      final double x = (size.width * (i * 0.13 + animationValue * 0.1)) % size.width;
      final double y = (size.height * (i * 0.17 + animationValue * 0.05)) % size.height;
      final double radius = 2 + (i % 3);
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 