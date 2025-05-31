import 'package:flutter/material.dart';
import 'app_color.dart';

/// Custom theme extensions to provide additional styling options
/// beyond what's available in the standard Flutter Theme

/// Extension for custom card styles used throughout the app
class CardStyles extends ThemeExtension<CardStyles> {
  final BoxDecoration elevated;
  final BoxDecoration flat;
  final BoxDecoration highlighted;

  CardStyles({
    required this.elevated,
    required this.flat,
    required this.highlighted,
  });

  static CardStyles get light => CardStyles(
    elevated: BoxDecoration(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    flat: BoxDecoration(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColor.divider),
    ),
    highlighted: BoxDecoration(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColor.primaryLight),
      boxShadow: [
        BoxShadow(
          color: AppColor.primaryLighter.withValues(alpha: 0.5),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
  );

  @override
  CardStyles copyWith({
    BoxDecoration? elevated,
    BoxDecoration? flat,
    BoxDecoration? highlighted,
  }) {
    return CardStyles(
      elevated: elevated ?? this.elevated,
      flat: flat ?? this.flat,
      highlighted: highlighted ?? this.highlighted,
    );
  }

  @override
  ThemeExtension<CardStyles> lerp(ThemeExtension<CardStyles>? other, double t) {
    if (other is! CardStyles) {
      return this;
    }
    return CardStyles(
      elevated: BoxDecoration.lerp(elevated, other.elevated, t)!,
      flat: BoxDecoration.lerp(flat, other.flat, t)!,
      highlighted: BoxDecoration.lerp(highlighted, other.highlighted, t)!,
    );
  }
}

/// Extension for book item styling used in the library views
class BookItemStyles extends ThemeExtension<BookItemStyles> {
  final TextStyle titleStyle;
  final TextStyle categoryStyle;
  final TextStyle authorStyle;
  final TextStyle metadataStyle;
  final EdgeInsets gridItemPadding;
  final EdgeInsets listItemPadding;

  BookItemStyles({
    required this.titleStyle,
    required this.categoryStyle,
    required this.authorStyle,
    required this.metadataStyle,
    required this.gridItemPadding,
    required this.listItemPadding,
  });

  static BookItemStyles get light => BookItemStyles(
    titleStyle: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColor.textPrimary,
    ),
    categoryStyle: TextStyle(
      fontSize: 12,
      color: AppColor.textSecondary,
    ),
    authorStyle: TextStyle(
      fontSize: 12,
      color: AppColor.textSecondary,
    ),
    metadataStyle: TextStyle(
      fontSize: 10,
      color: AppColor.textLight,
    ),
    gridItemPadding: EdgeInsets.all(8),
    listItemPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  );

  @override
  BookItemStyles copyWith({
    TextStyle? titleStyle,
    TextStyle? categoryStyle,
    TextStyle? authorStyle,
    TextStyle? metadataStyle,
    EdgeInsets? gridItemPadding,
    EdgeInsets? listItemPadding,
  }) {
    return BookItemStyles(
      titleStyle: titleStyle ?? this.titleStyle,
      categoryStyle: categoryStyle ?? this.categoryStyle,
      authorStyle: authorStyle ?? this.authorStyle,
      metadataStyle: metadataStyle ?? this.metadataStyle,
      gridItemPadding: gridItemPadding ?? this.gridItemPadding,
      listItemPadding: listItemPadding ?? this.listItemPadding,
    );
  }

  @override
  ThemeExtension<BookItemStyles> lerp(ThemeExtension<BookItemStyles>? other, double t) {
    if (other is! BookItemStyles) {
      return this;
    }
    return BookItemStyles(
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, t)!,
      categoryStyle: TextStyle.lerp(categoryStyle, other.categoryStyle, t)!,
      authorStyle: TextStyle.lerp(authorStyle, other.authorStyle, t)!,
      metadataStyle: TextStyle.lerp(metadataStyle, other.metadataStyle, t)!,
      gridItemPadding: EdgeInsets.lerp(gridItemPadding, other.gridItemPadding, t)!,
      listItemPadding: EdgeInsets.lerp(listItemPadding, other.listItemPadding, t)!,
    );
  }
}

/// Enhanced theme helper to register all theme extensions
class EnhancedTheme {
  /// Create an enhanced version of the app theme with all extensions
  static ThemeData enhance(ThemeData base) {
    return base.copyWith(
      extensions: [
        CardStyles.light,
        BookItemStyles.light,
        // Add other theme extensions here if needed
        // e.g., ...(base.extensions ?? []), // Keep existing extensions if any
      ],
    );
  }
  
  /// Helper method to get card styles from theme
  static CardStyles cardStyles(BuildContext context) {
    return Theme.of(context).extension<CardStyles>() ?? CardStyles.light;
  }
  
  /// Helper method to get book item styles from theme
  static BookItemStyles bookItemStyles(BuildContext context) {
    return Theme.of(context).extension<BookItemStyles>() ?? BookItemStyles.light;
  }
}
