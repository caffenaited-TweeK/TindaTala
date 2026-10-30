import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../data/product_image_store.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.store});

  final AppStore store;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _storeNameController;
  late int _lowStockThreshold;
  late int _expirationWarningDays;
  late String? _storeImagePath;
  final _imageStore = ProductImageStore();
  bool _hasUnsavedStoreImageChanges = false;
  bool _isSaving = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController(
      text: widget.store.settings.storeName,
    );
    _lowStockThreshold = widget.store.settings.lowStockThreshold;
    _expirationWarningDays = widget.store.settings.expirationWarningDays;
    _storeImagePath = widget.store.settings.storeImagePath;
    widget.store.addListener(_syncStoreImage);
  }

  @override
  void dispose() {
    widget.store.removeListener(_syncStoreImage);
    _storeNameController.dispose();
    super.dispose();
  }

  void _syncStoreImage() {
    final savedPath = widget.store.settings.storeImagePath;
    if (_hasUnsavedStoreImageChanges || savedPath == _storeImagePath) return;
    setState(() => _storeImagePath = savedPath);
  }

  Future<void> _saveSettings() async {
    final storeName = _storeNameController.text.trim();
    if (storeName.isEmpty) {
      showAppMessage(context, 'Enter your store name.', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.store.updateSettings(
        widget.store.settings.copyWith(
          storeName: storeName,
          storeImagePath: _storeImagePath,
          removeStoreImage: _storeImagePath == null,
          lowStockThreshold: _lowStockThreshold,
          expirationWarningDays: _expirationWarningDays,
        ),
      );
      if (mounted) {
        setState(() {
          _storeImagePath = widget.store.settings.storeImagePath;
          _hasUnsavedStoreImageChanges = false;
        });
      }
      if (mounted) showAppMessage(context, 'Store settings saved.');
    } catch (error) {
      if (mounted) {
        showAppMessage(context, readableError(error), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectStoreImage() async {
    setState(() => _isPickingImage = true);
    try {
      final path = await _imageStore.pickAndSaveImage(
        ownerId: widget.store.currentAccount!.normalizedUsername,
        directoryName: 'store',
      );
      if (path != null && mounted) {
        setState(() {
          _storeImagePath = path;
          _hasUnsavedStoreImageChanges = true;
        });
      }
    } catch (error) {
      if (mounted) {
        showAppMessage(
          context,
          'Could not choose that photo. ${readableError(error)}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: TindaColors.cream,
        title: const Text('Add a product category'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 32,
            decoration: const InputDecoration(hintText: 'e.g. Frozen goods'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a category name.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, controller.text.trim());
            },
            child: const Text('Add category'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;
    if (widget.store.settings.categories.any(
      (category) => category.toLowerCase() == name.toLowerCase(),
    )) {
      showAppMessage(context, 'That category already exists.', isError: true);
      return;
    }
    try {
      await widget.store.updateSettings(
        widget.store.settings.copyWith(
          categories: [...widget.store.settings.categories, name],
        ),
      );
      if (mounted) showAppMessage(context, '$name category added.');
    } catch (error) {
      if (mounted) {
        showAppMessage(context, readableError(error), isError: true);
      }
    }
  }

  Future<void> _removeCategory(String category) async {
    if (widget.store.products.any((product) => product.category == category)) {
      showAppMessage(
        context,
        'Move or delete products in $category before removing the category.',
        isError: true,
      );
      return;
    }
    final confirmed = await confirmAction(
      context,
      title: 'Remove $category?',
      message: 'Products will not be deleted, but this category will no longer be available.',
      confirmLabel: 'Remove category',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await widget.store.updateSettings(
        widget.store.settings.copyWith(
          categories: widget.store.settings.categories
              .where((item) => item != category)
              .toList(),
        ),
      );
      if (mounted) showAppMessage(context, '$category category removed.');
    } catch (error) {
      if (mounted) {
        showAppMessage(context, readableError(error), isError: true);
      }
    }
  }

  Future<void> _signOut() async {
    final confirmed = await confirmAction(
      context,
      title: 'Sign out of TindaTala?',
      message:
          'Your products, sales, and account will stay saved on this device.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await widget.store.signOut();
    } catch (error) {
      if (mounted) {
        showAppMessage(context, readableError(error), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final store = widget.store;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Text(
              'A little more',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            PaperCard(
              color: const Color(0xFFFFF0CB),
              child: Row(
                children: [
                  StoreProfileImage(imagePath: _storeImagePath),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.settings.storeName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          'Your neighborhood inventory kasama',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Store information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 9),
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Store name',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    controller: _storeNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.storefront_outlined),
                      hintText: 'Your store name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Store picture (optional)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StoreProfileImage(imagePath: _storeImagePath, size: 58),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isPickingImage
                                  ? null
                                  : _selectStoreImage,
                              icon: _isPickingImage
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.photo_library_outlined),
                              label: const Text('Choose a photo'),
                            ),
                            if (_storeImagePath != null)
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _storeImagePath = null;
                                  _hasUnsavedStoreImageChanges = true;
                                }),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Remove photo'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your photo is private to this account.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Shelf reminders',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Low-stock threshold',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: _lowStockThreshold,
                    decoration: const InputDecoration(),
                    items: List.generate(
                      31,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text(
                          '$index ${index == 1 ? 'piece' : 'pieces'}',
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _lowStockThreshold = value);
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Alert when a product has this many pieces or fewer.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Expiration warning period',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: _expirationWarningDays,
                    decoration: const InputDecoration(),
                    items: const [1, 3, 7, 14, 30, 60, 90]
                        .map(
                          (days) => DropdownMenuItem(
                            value: days,
                            child: Text('$days days before expiration'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _expirationWarningDays = value);
                      }
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get a heads-up before products expire.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              color: TindaColors.ivory,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Save store settings'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Product categories',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            PaperCard(
              child: Wrap(
                spacing: 7,
                runSpacing: 4,
                children: [
                  for (final category in store.settings.categories)
                    InputChip(
                      avatar: CategoryArtwork(category: category, size: 23),
                      label: Text(category),
                      deleteIcon: const Icon(Icons.close, size: 15),
                      onDeleted: () => _removeCategory(category),
                      backgroundColor: const Color(0xFFFFF0CB),
                      side: const BorderSide(color: TindaColors.brown),
                      labelStyle: const TextStyle(
                        color: TindaColors.brown,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Account information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 9),
            PaperCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    color: TindaColors.brown,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.currentAccount?.username ?? 'Store owner',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Account and inventory saved on this device',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'About the app',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 9),
            PaperCard(
              child: Row(
                children: [
                  const TindaLogo(size: 66),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TindaTala · Version 1.0.0',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sari-Sari Store Inventory Management System',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Made with malasakit, for your everyday tala.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('sign-out-button'),
              onPressed: _signOut,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TindaColors.error,
                side: const BorderSide(color: TindaColors.error, width: 1.3),
              ),
            ),
          ],
        );
      },
    );
  }
}
