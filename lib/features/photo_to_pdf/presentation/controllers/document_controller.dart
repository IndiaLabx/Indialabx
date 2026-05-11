import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsathi/features/photo_to_pdf/data/models/document_model.dart';
import 'package:docsathi/features/photo_to_pdf/data/repositories/document_repository.dart';

final documentRepositoryProvider = Provider((ref) => DocumentRepository());

final documentListProvider =
    NotifierProvider<DocumentListNotifier, List<DocumentModel>>(() {
      return DocumentListNotifier();
    });

class DocumentListNotifier extends Notifier<List<DocumentModel>> {
  @override
  List<DocumentModel> build() {
    return ref.read(documentRepositoryProvider).getAllDocuments();
  }

  void loadDocuments() {
    state = ref.read(documentRepositoryProvider).getAllDocuments();
  }

  Future<void> addDocument(DocumentModel document) async {
    await ref.read(documentRepositoryProvider).saveDocument(document);
    loadDocuments();
  }

  Future<void> deleteDocument(String id) async {
    await ref.read(documentRepositoryProvider).deleteDocument(id);
    loadDocuments();
  }
}
