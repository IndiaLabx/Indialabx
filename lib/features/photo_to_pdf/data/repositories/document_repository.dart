import 'package:hive/hive.dart';
import 'package:docsathi/features/photo_to_pdf/data/models/document_model.dart';
import 'dart:io';

class DocumentRepository {
  final Box<DocumentModel> _box = Hive.box<DocumentModel>('documents');

  List<DocumentModel> getAllDocuments() {
    return _box.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveDocument(DocumentModel document) async {
    await _box.put(document.id, document);
  }

  Future<void> deleteDocument(String id) async {
    final doc = _box.get(id);
    if (doc != null) {
      final file = File(doc.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      await _box.delete(id);
    }
  }
}
