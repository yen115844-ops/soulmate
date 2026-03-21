import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class OptimizedUploadImage {
  final String path;
  final bool isTemp;

  const OptimizedUploadImage({required this.path, required this.isTemp});

  Future<void> dispose() async {
    if (!isTemp) return;

    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best effort cleanup only.
    }
  }
}

class ImageUploadOptimizer {
  ImageUploadOptimizer._();

  static Future<OptimizedUploadImage> optimize(
    String inputPath, {
    int maxWidth = 1280,
    int maxHeight = 1280,
    int quality = 84,
    int targetMaxBytes = 2 * 1024 * 1024,
  }) async {
    final source = File(inputPath);
    if (!await source.exists()) {
      return OptimizedUploadImage(path: inputPath, isTemp: false);
    }

    final sourceSize = await source.length();

    // Skip compression for already small files to avoid extra I/O and CPU.
    if (sourceSize <= targetMaxBytes) {
      return OptimizedUploadImage(path: inputPath, isTemp: false);
    }

    final tempPath = _buildTempPath(inputPath);

    try {
      final compressed = await FlutterImageCompress.compressAndGetFile(
        inputPath,
        tempPath,
        format: CompressFormat.jpeg,
        minWidth: maxWidth,
        minHeight: maxHeight,
        quality: quality,
        keepExif: false,
        autoCorrectionAngle: true,
      );

      if (compressed == null) {
        return OptimizedUploadImage(path: inputPath, isTemp: false);
      }

      final compressedSize = await File(compressed.path).length();
      if (compressedSize >= sourceSize) {
        await _safeDelete(compressed.path);
        return OptimizedUploadImage(path: inputPath, isTemp: false);
      }

      return OptimizedUploadImage(path: compressed.path, isTemp: true);
    } catch (e) {
      debugPrint('Image optimize failed, fallback original: $e');
      await _safeDelete(tempPath);
      return OptimizedUploadImage(path: inputPath, isTemp: false);
    }
  }

  static String _buildTempPath(String originalPath) {
    final dot = originalPath.lastIndexOf('.');
    final base = dot > 0 ? originalPath.substring(0, dot) : originalPath;
    return '${base}_upload.jpg';
  }

  static Future<void> _safeDelete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best effort cleanup only.
    }
  }
}
