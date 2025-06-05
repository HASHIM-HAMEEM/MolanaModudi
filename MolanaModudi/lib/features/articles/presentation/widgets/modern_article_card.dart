import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:modudi/core/themes/app_color.dart';
import '../../domain/entities/article_entity.dart';

/// Modern article card with AI features and enhanced UI
class ModernArticleCard extends ConsumerStatefulWidget {
  final ArticleEntity article;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onAudio;
  final bool isFavorite;
  final bool showActions;
  final CardSize size;

  const ModernArticleCard({
    super.key,
    required this.article,
    this.onTap,
    this.onFavorite,
    this.onShare,
    this.onAudio,
    this.isFavorite = false,
    this.showActions = true,
    this.size = CardSize.normal,
  });

  @override
  ConsumerState<ModernArticleCard> createState() => _ModernArticleCardState();
}

class _ModernArticleCardState extends ConsumerState<ModernArticleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSepia = theme.scaffoldBackgroundColor == AppColor.backgroundSepia;

    final cardBg = isDark
        ? AppColor.surfaceDark
        : isSepia
            ? AppColor.surfaceSepia
            : Colors.white;

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

    final accentColor = isDark
        ? AppColor.accentDark
        : isSepia
            ? AppColor.accentSepia
            : AppColor.accent;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: _buildCard(
              cardBg,
              textColor,
              secondaryTextColor,
              accentColor,
              isDark,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(
    Color cardBg,
    Color textColor,
    Color secondaryTextColor,
    Color accentColor,
    bool isDark,
  ) {
    final cardHeight = widget.size == CardSize.compact ? 120.0 : 180.0;
    final imageSize = widget.size == CardSize.compact ? 80.0 : 120.0;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap,
      child: Container(
        height: cardHeight,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
          border: Border.all(
            color: accentColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // Article Image
              _buildArticleImage(imageSize, accentColor, isDark),
              
              // Content Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Badge
                      _buildCategoryBadge(accentColor),
                      
                      const SizedBox(height: 8),
                      
                      // Title
                      _buildTitle(textColor),
                      
                      const SizedBox(height: 6),
                      
                      // Summary
                      _buildSummary(secondaryTextColor),
                      
                      const Spacer(),
                      
                      // Bottom Row
                      _buildBottomRow(secondaryTextColor, accentColor),
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

  Widget _buildArticleImage(double size, Color accentColor, bool isDark) {
    return Container(
      width: size,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.1),
            accentColor.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: widget.article.imageUrl != null
          ? CachedNetworkImage(
              imageUrl: widget.article.imageUrl!,
              fit: BoxFit.cover,
              cacheKey: 'article_${widget.article.id}',
              placeholder: (context, url) => Container(
                color: accentColor.withValues(alpha: 0.1),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => _buildPlaceholderIcon(accentColor),
            )
          : _buildPlaceholderIcon(accentColor),
    );
  }

  Widget _buildPlaceholderIcon(Color accentColor) {
    return Icon(
      Icons.article_outlined,
      size: 32,
      color: accentColor.withValues(alpha: 0.6),
    );
  }

  Widget _buildCategoryBadge(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.article.category,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: accentColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTitle(Color textColor) {
    final fontSize = widget.size == CardSize.compact ? 14.0 : 16.0;
    final maxLines = widget.size == CardSize.compact ? 2 : 2;

    return Text(
      widget.article.title,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: textColor,
        height: 1.3,
        letterSpacing: -0.2,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSummary(Color secondaryTextColor) {
    if (widget.size == CardSize.compact) {
      return const SizedBox.shrink();
    }

    return Text(
      widget.article.summary,
      style: TextStyle(
        fontSize: 13,
        color: secondaryTextColor,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildBottomRow(Color secondaryTextColor, Color accentColor) {
    return Row(
      children: [
        // Reading time with icon
        Icon(
          Icons.schedule_outlined,
          size: 14,
          color: secondaryTextColor,
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.article.estimatedReadTime} min read',
          style: TextStyle(
            fontSize: 12,
            color: secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        // AI Badge if available
        if (widget.article.keyInsights != null &&
            widget.article.keyInsights!.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology_outlined,
                  size: 10,
                  color: accentColor,
                ),
                const SizedBox(width: 2),
                Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const Spacer(),
        
        // Action buttons
        if (widget.showActions) _buildActionButtons(accentColor),
      ],
    );
  }

  Widget _buildActionButtons(Color accentColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Audio button
        if (widget.article.audioUrl != null || widget.onAudio != null)
          _buildActionButton(
            icon: Icons.volume_up_outlined,
            onTap: widget.onAudio,
            color: accentColor,
          ),
        
        // Favorite button
        if (widget.onFavorite != null)
          _buildActionButton(
            icon: widget.isFavorite
                ? Icons.favorite
                : Icons.favorite_border_outlined,
            onTap: widget.onFavorite,
            color: widget.isFavorite ? Colors.red : accentColor,
          ),
        
        // Share button
        if (widget.onShare != null)
          _buildActionButton(
            icon: Icons.share_outlined,
            onTap: widget.onShare,
            color: accentColor,
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }
}

/// Card size variants
enum CardSize {
  compact,
  normal,
  featured,
}

/// Extension for CardSize
extension CardSizeExtension on CardSize {
  double get height {
    switch (this) {
      case CardSize.compact:
        return 120;
      case CardSize.normal:
        return 180;
      case CardSize.featured:
        return 220;
    }
  }
} 