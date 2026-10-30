import 'package:tindatala/data/local_store.dart';
import 'package:tindatala/data/models.dart';

class MemoryStoreRepository implements StoreRepository {
  StoreData data = const StoreData();

  @override
  Future<StoreData> load() async => data;

  @override
  Future<void> save(StoreData data) async {
    this.data = data;
  }
}
