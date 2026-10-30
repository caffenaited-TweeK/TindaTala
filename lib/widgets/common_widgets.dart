import 'dart:io';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';

String peso(double amount) => '₱${amount.toStringAsFixed(2)}';

String shortDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';

String shortDateTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '${shortDate(date)} · $hour:$minute $period';
}

String _month(int number) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[number - 1];
}

String statusLabel(ProductStatus status) => switch (status) {
  ProductStatus.expired => 'Expired',
  ProductStatus.lowStock => 'Low stock',
  ProductStatus.nearExpiration => 'Near expiration',
  ProductStatus.inStock => 'In stock',
};

Color statusColor(ProductStatus status) => switch (status) {
  ProductStatus.expired => TindaColors.error,
  ProductStatus.lowStock => TindaColors.amber,
  ProductStatus.nearExpiration => TindaColors.blue,
  ProductStatus.inStock => TindaColors.green,
};

class TindaLogo extends StatelessWidget {
  const TindaLogo({super.key, this.size = 46});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.asset(
        'assets/designs/images/TindaTala_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'TindaTala sari-sari store logo',
      ),
    );
  }
}

class StoreProfileImage extends StatelessWidget {
  const StoreProfileImage({super.key, this.imagePath, this.size = 52});

  final String? imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    return Semantics(
      label: 'Store profile picture',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: TindaColors.yellow,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: TindaColors.brown),
        ),
        clipBehavior: Clip.antiAlias,
        child: path != null && File(path).existsSync()
            ? Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _storeIcon(),
              )
            : _storeIcon(),
      ),
    );
  }

  Widget _storeIcon() => Icon(
    Icons.storefront_outlined,
    color: TindaColors.brown,
    size: size * 0.54,
  );
}

class StoreArtwork extends StoreProfileImage {
  const StoreArtwork({super.key, super.imagePath, super.size = 52});
}

class CategoryArtwork extends StatelessWidget {
  const CategoryArtwork({super.key, required this.category, this.size = 30});

  final String category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sticker = _productSticker('', category);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: sticker.background,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: sticker.accent.withValues(alpha: 0.75)),
      ),
      child: Text(
        sticker.emoji,
        style: TextStyle(fontSize: size * 0.58, height: 1),
      ),
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.imagePath,
  });

  final String title;
  final String? subtitle;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          StoreProfileImage(imagePath: imagePath),
        ],
      ),
    );
  }
}

class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color = TindaColors.ivory,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(padding: padding, child: child),
    );
  }
}

class ProductArtwork extends StatelessWidget {
  const ProductArtwork({
    super.key,
    required this.name,
    required this.category,
    this.imagePath,
    this.size = 64,
  });

  final String name;
  final String category;
  final String? imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final sticker = _productSticker(name, category);
    final filePath = imagePath;
    return Semantics(
      label: '$name product illustration',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: sticker.background,
          borderRadius: BorderRadius.circular(size * 0.22),
          border: Border.all(color: TindaColors.brown, width: 1.3),
          boxShadow: const [
            BoxShadow(color: Color(0x16000000), offset: Offset(0, 2)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: filePath != null && File(filePath).existsSync()
            ? Image.file(
                File(filePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    _StickerGraphic(sticker: sticker, size: size),
              )
            : _StickerGraphic(sticker: sticker, size: size),
      ),
    );
  }
}

class _ProductSticker {
  const _ProductSticker(this.emoji, this.background, this.accent);

  final String emoji;
  final Color background;
  final Color accent;
}

_ProductSticker _productSticker(String name, String category) {
  final words = '$name $category'.toLowerCase();
  if (words.contains('sardine') || words.contains('canned')) {
    return const _ProductSticker('🐟', Color(0xFFFFE6D7), Color(0xFFC9432F));
  }
  if (words.contains('noodle') || words.contains('pancit')) {
    return const _ProductSticker('🍜', Color(0xFFFFF0CB), Color(0xFFF4B83F));
  }
  if (words.contains('biscuit') || words.contains('cookie')) {
    return const _ProductSticker('🍪', Color(0xFFF6E5CB), Color(0xFFD98A16));
  }
  if (words.contains('chip') || words.contains('snack')) {
    return const _ProductSticker('🍿', Color(0xFFFFF0CB), Color(0xFFF4B83F));
  }
  if (words.contains('soda') ||
      words.contains('cola') ||
      words.contains('drink')) {
    return const _ProductSticker('🥤', Color(0xFFE7F0F2), Color(0xFF397CA5));
  }
  if (words.contains('water')) {
    return const _ProductSticker('💧', Color(0xFFE7F0F2), Color(0xFF397CA5));
  }
  if (words.contains('coffee') || words.contains('kopiko')) {
    return const _ProductSticker('☕', Color(0xFFF1E4D6), Color(0xFF806653));
  }
  if (words.contains('milk') || words.contains('dairy')) {
    return const _ProductSticker('🥛', Color(0xFFE7F0F2), Color(0xFF397CA5));
  }
  if (words.contains('candy') || words.contains('sweet')) {
    return const _ProductSticker('🍬', Color(0xFFFBE8E1), Color(0xFFC9432F));
  }
  if (words.contains('shampoo')) {
    return const _ProductSticker('🧴', Color(0xFFECE8F7), Color(0xFF8066A3));
  }
  if (words.contains('soap')) {
    return const _ProductSticker('🧼', Color(0xFFE7F0E7), Color(0xFF397A4A));
  }
  if (words.contains('detergent')) {
    return const _ProductSticker('🫧', Color(0xFFE7F0F2), Color(0xFF397CA5));
  }
  if (words.contains('personal')) {
    return const _ProductSticker('🧴', Color(0xFFECE8F7), Color(0xFF8066A3));
  }
  if (words.contains('drink')) {
    return const _ProductSticker('🥤', Color(0xFFE7F0F2), Color(0xFF397CA5));
  }
  return const _ProductSticker('🛍️', Color(0xFFFFF0CB), Color(0xFFF4B83F));
}

class _StickerGraphic extends StatelessWidget {
  const _StickerGraphic({required this.sticker, required this.size});

  final _ProductSticker sticker;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          right: size * 0.09,
          top: size * 0.08,
          child: Icon(
            Icons.auto_awesome,
            size: size * 0.16,
            color: sticker.accent,
          ),
        ),
        Container(
          margin: EdgeInsets.all(size * 0.13),
          decoration: BoxDecoration(
            color: TindaColors.ivory.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(size * 0.16),
            border: Border.all(color: sticker.accent.withValues(alpha: 0.65)),
          ),
          child: Center(
            child: Text(
              sticker.emoji,
              style: TextStyle(fontSize: size * 0.45, height: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class StockStatusBadge extends StatelessWidget {
  const StockStatusBadge({super.key, required this.status});

  final ProductStatus status;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            statusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(ProductStatus value) => switch (value) {
    ProductStatus.expired => Icons.error_outline_rounded,
    ProductStatus.lowStock => Icons.inventory_2_outlined,
    ProductStatus.nearExpiration => Icons.event_available_outlined,
    ProductStatus.inStock => Icons.check_circle_outline_rounded,
  };
}

class EmptyShelf extends StatelessWidget {
  const EmptyShelf({
    super.key,
    required this.title,
    required this.detail,
    this.action,
  });

  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      child: Column(
        children: [
          const Text('✨  ♡', style: TextStyle(fontSize: 26)),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: TindaColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: TindaColors.brown, width: 1.3),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('confirm-action-button'),
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: TindaColors.error)
                  : null,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}

void showAppMessage(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: isError ? TindaColors.error : TindaColors.brown,
        content: Text(message),
      ),
    );
}

String readableError(Object error) {
  if (error is ArgumentError) {
    final message = error.message;
    return message?.toString() ?? 'Check the information and try again.';
  }
  if (error is StateError) return error.message.toString();
  return 'Could not save your changes. Please try again.';
}
