import 'package:hive/hive.dart';

class DocumentModel {
  final String id;
  final String filePath;
  final String fileName;
  final DateTime createdAt;
  final int sizeInBytes;
  final int pageCount;

  DocumentModel({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    required this.sizeInBytes,
    required this.pageCount,
  });
}

class DocumentModelAdapter extends TypeAdapter<DocumentModel> {
  @override
  final int typeId = 0;

  @override
  DocumentModel read(BinaryReader reader) {
    return DocumentModel(
      id: reader.readString(),
      filePath: reader.readString(),
      fileName: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      sizeInBytes: reader.readInt(),
      pageCount: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, DocumentModel obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.filePath);
    writer.writeString(obj.fileName);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.sizeInBytes);
    writer.writeInt(obj.pageCount);
  }
}
