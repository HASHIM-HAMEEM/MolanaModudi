import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../core/themes/app_font_helper.dart';
import '../../../settings/presentation/providers/app_settings_provider.dart';

class AnimatedQuoteWidget extends StatefulWidget {
  final AppThemeMode theme;
  final double fontScale;

  const AnimatedQuoteWidget({
    super.key,
    required this.theme,
    required this.fontScale,
  });

  @override
  State<AnimatedQuoteWidget> createState() => _AnimatedQuoteWidgetState();
}

class _AnimatedQuoteWidgetState extends State<AnimatedQuoteWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  int _currentQuoteIndex = 0;
  
  // Collection of inspiring quotes from Molana Moududi
  final List<Map<String, String>> _quotes = [
    {
      'text': 'اسلام محض ایک مذہب نہیں بلکہ ایک مکمل طریقہ حیات ہے',
      'translation': 'Islam is not merely a religion but a complete way of life'
    },
    {
      'text': 'علم حاصل کرنا ہر مسلمان مرد اور عورت پر فرض ہے',
      'translation': 'Seeking knowledge is obligatory upon every Muslim man and woman'
    },
    {
      'text': 'جب تک انسان خود کو نہیں بدلتا، خدا اس کے حالات نہیں بدلتا',
      'translation': 'Until man changes himself, God does not change his circumstances'
    },
    {
      'text': 'دین کا مقصد انسان کی فلاح اور بہتری ہے',
      'translation': 'The purpose of religion is human welfare and betterment'
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _startQuoteRotation();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));

    _controller.forward();
  }

  void _startQuoteRotation() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _nextQuote();
      }
    });
  }

  void _nextQuote() {
    if (!mounted) return;
    
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentQuoteIndex = (_currentQuoteIndex + 1) % _quotes.length;
        });
        _controller.forward().then((_) {
          _startQuoteRotation();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final quote = _quotes[_currentQuoteIndex];
        
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
                          child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _getThemeColor(widget.theme).withValues(alpha: 0.05),
                  border: Border.all(
                    color: _getThemeColor(widget.theme).withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Quote icon
                  Icon(
                    Icons.format_quote,
                    color: _getThemeColor(widget.theme).withValues(alpha: 0.6),
                    size: 20,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Arabic/Urdu quote
                  Text(
                    quote['text']!,
                    style: GoogleFonts.amiri(
                      textStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _getThemeColor(widget.theme),
                        height: 1.4,
                      ).withAppFontScale(widget.fontScale),
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // English translation
                  Text(
                    quote['translation']!,
                    style: GoogleFonts.poppins(
                      textStyle: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: _getThemeColor(widget.theme).withValues(alpha: 0.7),
                        height: 1.3,
                      ).withAppFontScale(widget.fontScale),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Quote dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_quotes.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentQuoteIndex
                              ? _getThemeColor(widget.theme)
                              : _getThemeColor(widget.theme).withValues(alpha: 0.3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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