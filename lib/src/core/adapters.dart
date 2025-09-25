import 'package:hive/hive.dart';
import '../infinite_query.dart';

/// Hive type adapter for QueryPage to enable persistent caching
class QueryPageAdapter<T> extends TypeAdapter<QueryPage<T>> {
  @override
  final int typeId = 0; // Unique ID for this adapter

  @override
  QueryPage<T> read(BinaryReader reader) {
    final data = reader.read() as T;
    final pageParam = reader.read();
    return QueryPage<T>(data: data, pageParam: pageParam);
  }

  @override
  void write(BinaryWriter writer, QueryPage<T> obj) {
    writer.write(obj.data);
    writer.write(obj.pageParam);
  }
}

/// Registers all necessary type adapters for the query cache
void registerQueryAdapters() {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(QueryPageAdapter());
  }
}
