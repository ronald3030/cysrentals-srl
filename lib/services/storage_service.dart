import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _bucketName = 'equipment-images';

  /// Subir imagen de equipo
  static Future<String> uploadEquipmentImage(File imageFile, String equipmentId) async {
    try {
      // Crear nombre único para la imagen
      final extension = path.extension(imageFile.path);
      final fileName = '${equipmentId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final filePath = 'equipment/$fileName';

      // Subir archivo
      await _client.storage
          .from(_bucketName)
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Obtener URL pública
      final publicUrl = _client.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  /// Eliminar imagen de equipo
  static Future<void> deleteEquipmentImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;

      // Extraer el path del archivo de la URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      // El path está después de /storage/v1/object/public/{bucket}/
      if (pathSegments.length >= 5) {
        final filePath = pathSegments.sublist(5).join('/');
        
        await _client.storage
            .from(_bucketName)
            .remove([filePath]);
      }
    } catch (e) {
      // Silenciosamente fallar si no se puede eliminar la imagen
      print('Error al eliminar imagen: $e');
    }
  }

  /// Inicializar bucket (crear si no existe)
  static Future<void> initializeBucket() async {
    try {
      // Verificar si el bucket existe
      final buckets = await _client.storage.listBuckets();
      final bucketExists = buckets.any((b) => b.name == _bucketName);

      if (!bucketExists) {
        // Crear bucket público
        await _client.storage.createBucket(
          _bucketName,
          const BucketOptions(
            public: true,
            fileSizeLimit: '5MB',
            allowedMimeTypes: ['image/jpeg', 'image/png', 'image/jpg'],
          ),
        );
      }
    } catch (e) {
      print('Bucket ya existe o error al crear: $e');
    }
  }
}
