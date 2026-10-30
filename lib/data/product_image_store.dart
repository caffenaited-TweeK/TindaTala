import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProductImageStore {
  ProductImageStore({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickAndSaveImage({
    required String ownerId,
    String directoryName = 'products',
  }) async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1400,
    );
    if (image == null) return null;

    final directory = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory(
      '${directory.path}/account_images/$ownerId/$directoryName',
    );
    await imageDirectory.create(recursive: true);

    final extension = _extensionFor(image.name);
    final savedPath =
        '${imageDirectory.path}/${DateTime.now().microsecondsSinceEpoch}$extension';
    await File(image.path).copy(savedPath);
    return savedPath;
  }

  String _extensionFor(String filename) {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex < 0) return '.jpg';
    final extension = filename.substring(dotIndex).toLowerCase();
    if (!RegExp(r'^\.[a-z0-9]{1,5}$').hasMatch(extension)) return '.jpg';
    return extension;
  }
}
