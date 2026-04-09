import 'package:shared_models/shared_models.dart';

abstract class CategoriesRepository {
  Stream<List<Category>> watchAll();

  Future<List<Category>> fetchAll();

  Future<void> upsert(Category category);

  Future<void> upsertMany(List<Category> categories);

  Future<void> softDelete(String id, {DateTime? deletedAt});
}

