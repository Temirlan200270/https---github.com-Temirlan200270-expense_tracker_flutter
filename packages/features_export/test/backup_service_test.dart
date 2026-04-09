import 'dart:io';

import 'package:features_export/src/services/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_db/local_db.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('BackupService Tests', () {
    late AppDatabase database;
    late LocalExpensesRepository expensesRepo;
    late LocalCategoriesRepository categoriesRepo;
    late BackupService backupService;

    setUp(() async {
      database = AppDatabase();
      expensesRepo = LocalExpensesRepository(database);
      categoriesRepo = LocalCategoriesRepository(database);
      backupService = BackupService(
        database: database,
        expensesRepo: expensesRepo,
        categoriesRepo: categoriesRepo,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('создание бэкапа сохраняет все данные', () async {
      // Создаём тестовые данные
      final category = Category(
        name: 'Тестовая категория',
        colorValue: 0xFF4CAF50,
        kind: CategoryKind.expense,
      );
      await categoriesRepo.upsertMany([category]);

      final expense = Expense(
        id: Uuid().v4(),
        amount: Money(amountInCents: 10000, currencyCode: 'KZT'),
        type: ExpenseType.expense,
        occurredAt: DateTime.now(),
        categoryId: category.id,
        note: 'Тестовый расход',
      );
      await expensesRepo.upsertExpense(expense);

      // Создаём бэкап
      final backupFile = await backupService.createBackup();

      // Проверяем, что файл создан
      expect(await backupFile.exists(), isTrue);
      expect(backupFile.path.contains('expense_tracker_backup_'), isTrue);
      expect(backupFile.path.endsWith('.json'), isTrue);

      // Очищаем
      await backupFile.delete();
    });

    test('восстановление бэкапа восстанавливает все данные', () async {
      // Создаём тестовые данные
      final category = Category(
        name: 'Тестовая категория',
        colorValue: 0xFF4CAF50,
        kind: CategoryKind.expense,
      );
      await categoriesRepo.upsertMany([category]);

      final expense = Expense(
        id: Uuid().v4(),
        amount: Money(amountInCents: 10000, currencyCode: 'KZT'),
        type: ExpenseType.expense,
        occurredAt: DateTime.now(),
        categoryId: category.id,
        note: 'Тестовый расход',
      );
      await expensesRepo.upsertExpense(expense);

      // Создаём бэкап
      final backupFile = await backupService.createBackup();

      // Очищаем базу данных
      await expensesRepo.softDelete(expense.id);
      // Удаляем категорию через soft delete
      final deletedCategory = category.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
      await categoriesRepo.upsert(deletedCategory);

      // Проверяем, что данные удалены
      final expensesAfterDelete = await expensesRepo.fetchExpenses();
      final categoriesAfterDelete = await categoriesRepo.fetchAll();
      expect(expensesAfterDelete.where((e) => e.id == expense.id).isEmpty, isTrue);
      expect(categoriesAfterDelete.where((c) => c.id == category.id).isEmpty, isTrue);

      // Восстанавливаем из бэкапа
      final result = await backupService.restoreBackup(backupFile);

      // Проверяем результат
      expect(result.success, isTrue);
      expect(result.expensesCount, 1);
      expect(result.categoriesCount, 1);

      // Проверяем, что данные восстановлены
      final restoredExpenses = await expensesRepo.fetchExpenses();
      final restoredCategories = await categoriesRepo.fetchAll();
      expect(restoredExpenses.any((e) => e.id == expense.id), isTrue);
      expect(restoredCategories.any((c) => c.id == category.id), isTrue);

      // Очищаем
      await backupFile.delete();
    });

    test('получение информации о бэкапе возвращает корректные данные', () async {
      // Создаём тестовые данные
      final category = Category(
        name: 'Тестовая категория',
        colorValue: 0xFF4CAF50,
        kind: CategoryKind.expense,
      );
      await categoriesRepo.upsertMany([category]);

      final expense = Expense(
        id: Uuid().v4(),
        amount: Money(amountInCents: 10000, currencyCode: 'KZT'),
        type: ExpenseType.expense,
        occurredAt: DateTime.now(),
        categoryId: category.id,
      );
      await expensesRepo.upsertExpense(expense);

      // Создаём бэкап
      final backupFile = await backupService.createBackup();

      // Получаем информацию
      final info = await backupService.getBackupInfo(backupFile);

      // Проверяем информацию
      expect(info, isNotNull);
      expect(info!.expensesCount, 1);
      expect(info.categoriesCount, 1);
      expect(info.fileSize, greaterThan(0));
      expect(info.createdAt, isNotNull);

      // Очищаем
      await backupFile.delete();
    });

    test('список бэкапов возвращает все созданные файлы', () async {
      // Создаём несколько бэкапов
      final backup1 = await backupService.createBackup();
      await Future.delayed(const Duration(milliseconds: 100));
      final backup2 = await backupService.createBackup();

      // Получаем список
      final backups = await backupService.listBackups();

      // Проверяем, что оба файла в списке
      expect(backups.length, greaterThanOrEqualTo(2));
      expect(backups.any((b) => b.path == backup1.path), isTrue);
      expect(backups.any((b) => b.path == backup2.path), isTrue);

      // Очищаем
      await backup1.delete();
      await backup2.delete();
    });

    test('удаление бэкапа удаляет файл', () async {
      // Создаём бэкап
      final backupFile = await backupService.createBackup();
      expect(await backupFile.exists(), isTrue);

      // Удаляем бэкап
      final deleted = await backupService.deleteBackup(backupFile);

      // Проверяем результат
      expect(deleted, isTrue);
      expect(await backupFile.exists(), isFalse);
    });

    test('восстановление из некорректного файла возвращает ошибку', () async {
      // Создаём некорректный файл
      final tempFile = File('${Directory.systemTemp.path}/invalid_backup.json');
      await tempFile.writeAsString('invalid json');

      // Пытаемся восстановить
      final result = await backupService.restoreBackup(tempFile);

      // Проверяем, что восстановление не удалось
      expect(result.success, isFalse);
      expect(result.error, isNotNull);

      // Очищаем
      await tempFile.delete();
    });

    test('восстановление из файла без версии возвращает ошибку', () async {
      // Создаём файл без версии
      final tempFile = File('${Directory.systemTemp.path}/no_version_backup.json');
      await tempFile.writeAsString('{"expenses": [], "categories": []}');

      // Пытаемся восстановить
      final result = await backupService.restoreBackup(tempFile);

      // Проверяем, что восстановление не удалось
      expect(result.success, isFalse);
      expect(result.error, contains('version'));

      // Очищаем
      await tempFile.delete();
    });
  });
}

