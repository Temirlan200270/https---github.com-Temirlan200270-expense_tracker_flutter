import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:expense_tracker_app/expense_tracker_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_models/shared_models.dart';
import 'package:ui_components/ui_components.dart';

import '../../controllers/expense_form_controller.dart';
import '../../providers/category_rules_providers.dart';
import '../../providers/categorization_providers.dart';
import '../../providers/expenses_providers.dart';
import '../widgets/category_search_field.dart';
import 'package:features_export/features_export.dart';

/// Сценарий SnackBar обучения после сохранения новой траты.
enum _LearningSnackKind { none, reinforce, correction }

/// Минимальная длина заметки, после которой вызываем Matching Engine на лету.
const int _kMinNoteLengthForLiveCategorize = 3;

class NewExpensePage extends ConsumerStatefulWidget {
  const NewExpensePage({
    super.key,
    this.initialType,
    this.expense,
  });

  final ExpenseType? initialType;
  final Expense? expense; // Если передан, то это редактирование

  @override
  ConsumerState<NewExpensePage> createState() => _NewExpensePageState();
}

class _NewExpensePageState extends ConsumerState<NewExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late ExpenseType _type;
  late DateTime _date;
  String? _categoryId;

  Timer? _noteDebounceTimer;
  CategorizationResult? _lastCategorizationResult;
  double? _suggestionConfidence;
  bool _categoryUserLocked = false;

  bool get _isEditing => widget.expense != null;

  /// Подсветка поля категории: совпало с последней авто-подсказкой, пользователь ещё не фиксировал выбор.
  bool get _highlightSuggestedCategory {
    if (_isEditing || _categoryUserLocked) return false;
    final r = _lastCategorizationResult;
    if (r == null ||
        r.source == CategorizationSource.none ||
        r.categoryId == null) {
      return false;
    }
    return r.categoryId == _categoryId;
  }

  String _categoryDisplayName(String? id) {
    if (id == null) return '';
    final list = ref.read(categoriesStreamProvider).valueOrNull;
    if (list == null) return id;
    for (final c in list) {
      if (c.id == id) return c.name;
    }
    return id;
  }

  /// Сценарий обучения после успешного сохранения новой транзакции.
  _LearningSnackKind _learningSnackKindAfterSave() {
    if (_isEditing) return _LearningSnackKind.none;
    final note = _noteController.text.trim();
    if (note.isEmpty || _categoryId == null) return _LearningSnackKind.none;
    final r = _lastCategorizationResult;

    if (r != null &&
        r.source == CategorizationSource.rule &&
        r.categoryId == _categoryId) {
      return _LearningSnackKind.none;
    }

    final reinforce = r != null &&
        r.source != CategorizationSource.rule &&
        r.source != CategorizationSource.none &&
        r.confidence >= 0.6 &&
        r.categoryId != null &&
        r.categoryId == _categoryId;

    if (reinforce) return _LearningSnackKind.reinforce;

    final predicted = r?.categoryId;
    final hadPrediction = r != null &&
        r.source != CategorizationSource.none &&
        predicted != null;

    if (hadPrediction && predicted != _categoryId) {
      return _LearningSnackKind.correction;
    }
    if (!hadPrediction) {
      if (note.length < 3) return _LearningSnackKind.none;
      return _LearningSnackKind.correction;
    }
    return _LearningSnackKind.none;
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final expense = widget.expense!;
      _type = expense.type;
      _date = expense.occurredAt;
      _categoryId = expense.categoryId;
      _amountController.text = expense.amount.amount.toString();
      _noteController.text = expense.note ?? '';
    } else {
      _type = widget.initialType ?? ExpenseType.expense;
      _date = DateTime.now();
      _noteController.addListener(_onNoteChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoFillFromLastTransaction();
      });
    }
  }

  void _autoFillFromLastTransaction() {
    final expensesAsync = ref.read(expensesStreamProvider);
    expensesAsync.whenData((expenses) {
      if (expenses.isEmpty || _isEditing) return;
      
      // Находим последнюю транзакцию того же типа
      final lastTransaction = expenses
          .where((e) => e.type == _type)
          .where((e) => !e.isDeleted)
          .toList()
        ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
      
      if (lastTransaction.isNotEmpty) {
        final last = lastTransaction.first;
        // Автозаполняем категорию, если она подходит
        if (last.categoryId != null && mounted) {
          setState(() {
            _categoryId = last.categoryId;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _noteDebounceTimer?.cancel();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onNoteChanged() {
    if (_isEditing) return;
    _categoryUserLocked = false;
    _noteDebounceTimer?.cancel();
    _noteDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _runCategorizationPipeline();
    });
  }

  void _runCategorizationPipeline() {
    if (_isEditing || !mounted) return;

    final trimmedNote = _noteController.text.trim();
    if (trimmedNote.length < _kMinNoteLengthForLiveCategorize) {
      setState(() {
        _lastCategorizationResult = CategorizationResult.empty;
        _suggestionConfidence = null;
      });
      return;
    }

    final rules = ref.read(categoryRulesStreamProvider).valueOrNull ?? [];
    final expenses = ref.read(expensesStreamProvider).valueOrNull ?? [];
    final categories = ref.read(categoriesStreamProvider).valueOrNull ?? [];
    final service = ref.read(categorizationServiceProvider);

    final result = service.suggestCategorySync(
      title: _noteController.text,
      type: _type,
      rules: rules,
      history: expenses,
      categories: categories,
    );
    if (!mounted) return;
    setState(() {
      _lastCategorizationResult = result;
      if (result.categoryId != null &&
          result.source != CategorizationSource.none) {
        _suggestionConfidence = result.confidence;
      } else {
        _suggestionConfidence = null;
      }
      if (!_categoryUserLocked && result.categoryId != null) {
        _categoryId = result.categoryId;
      }
    });
  }

  void _onCategoryChosenByUser(String? id) {
    setState(() {
      if (id != null) {
        _categoryUserLocked = true;
      } else {
        _categoryUserLocked = false;
      }
      _categoryId = id;
      _suggestionConfidence = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      ref.listen(categoryRulesStreamProvider, (_, __) {
        if (!mounted || _noteController.text.trim().isEmpty) return;
        _runCategorizationPipeline();
      });
      ref.listen(expensesStreamProvider, (_, __) {
        if (!mounted || _noteController.text.trim().isEmpty) return;
        _runCategorizationPipeline();
      });
    }

    ref.listen(expenseFormControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          final messenger = ScaffoldMessenger.of(context);
          final note = _noteController.text.trim();
          final categoryId = _categoryId;
          final kind = _learningSnackKindAfterSave();

          if (!_isEditing && kind == _LearningSnackKind.reinforce) {
            final theme = Theme.of(context);
            messenger.showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('expenses.form.success')),
                    const SizedBox(height: 10),
                    Text(
                      tr('expenses.form.learning.remember_choice_title'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr('expenses.form.learning.remember_prompt'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                action: SnackBarAction(
                  label: tr('expenses.form.learning.remember_action'),
                  onPressed: () {
                    if (categoryId != null) {
                      ref
                          .read(categoryRulesControllerProvider.notifier)
                          .createRuleFromText(
                            text: note,
                            categoryId: categoryId,
                          );
                    }
                  },
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          } else if (!_isEditing && kind == _LearningSnackKind.correction) {
            final theme = Theme.of(context);
            final snippet = extractKeywordFromNote(note);
            final short = snippet.length > 42
                ? '${snippet.substring(0, 39)}…'
                : snippet;
            final catName = _categoryDisplayName(categoryId);
            messenger.showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('expenses.form.success')),
                    const SizedBox(height: 10),
                    Text(
                      tr('expenses.form.learning.remember_choice_title'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tr(
                        'expenses.form.learning.remember_correction_body',
                        args: [short, catName],
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
                action: SnackBarAction(
                  label: tr('expenses.form.learning.remember_action'),
                  onPressed: () {
                    if (categoryId != null) {
                      ref
                          .read(categoryRulesControllerProvider.notifier)
                          .createRuleFromText(
                            text: note,
                            categoryId: categoryId,
                          );
                    }
                  },
                ),
                duration: const Duration(seconds: 6),
              ),
            );
          } else {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  _isEditing
                      ? tr('expenses.form.updated')
                      : tr('expenses.form.success'),
                ),
              ),
            );
          }
          if (mounted) Navigator.of(context).pop();
        },
        error: (error, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('expenses.form.error', args: [error.toString()]))),
          );
        },
      );
    });

    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final currencyCode = ref.watch(defaultCurrencyProvider);

    return PrimaryScaffold(
      title: _isEditing 
          ? tr('expenses.form.edit_title')
          : tr('expenses.form.title'),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(4),
              child: SegmentedButton<ExpenseType>(
                segments: [
                  ButtonSegment(
                    value: ExpenseType.expense,
                    label: Text(tr('expenses.form.expense')),
                    icon: const Icon(Icons.trending_down, size: 20),
                  ),
                  ButtonSegment(
                    value: ExpenseType.income,
                    label: Text(tr('expenses.form.income')),
                    icon: const Icon(Icons.trending_up, size: 20),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (value) {
                  setState(() {
                    _type = value.first;
                    _categoryUserLocked = false;
                  });
                  _runCategorizationPipeline();
                },
                style: SegmentedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 200.ms, curve: Curves.easeOutCubic)
                .slideY(
                    begin: -0.08,
                    end: 0,
                    duration: 220.ms,
                    curve: Curves.easeOutCubic),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: tr('expenses.form.amount'),
                      suffixText: currencyCode,
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.attach_money,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return tr('expenses.form.amount_required');
                      }
                      final parsed = double.tryParse(value.replaceAll(',', '.'));
                      if (parsed == null || parsed <= 0) {
                        return tr('expenses.form.amount_invalid');
                      }
                      return null;
                    },
                  )
                      .animate()
                      .fadeIn(
                          duration: 200.ms,
                          delay: 70.ms,
                          curve: Curves.easeOutCubic)
                      .slideX(
                          begin: -0.04,
                          end: 0,
                          duration: 220.ms,
                          delay: 70.ms,
                          curve: Curves.easeOutCubic),
                ),
                if (!_isEditing) ...[
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _scanReceipt(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.camera_alt,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(
                          duration: 200.ms,
                          delay: 100.ms,
                          curve: Curves.easeOutCubic)
                      .scale(
                          begin: const Offset(0.88, 0.88),
                          end: const Offset(1, 1),
                          duration: 220.ms,
                          delay: 100.ms,
                          curve: Curves.easeOutCubic),
                ],
              ],
            ),
            const SizedBox(height: 16),
            categoriesAsync.when(
              data: (categories) => CategorySearchField(
                categories: categories,
                selectedCategoryId: _categoryId,
                onCategorySelected: _onCategoryChosenByUser,
                type: _type,
                categorizationConfidence: _suggestionConfidence,
                highlightSuggested: _highlightSuggestedCategory,
              )
                  .animate()
                  .fadeIn(
                      duration: 200.ms,
                      delay: 130.ms,
                      curve: Curves.easeOutCubic)
                  .slideY(
                      begin: 0.08,
                      end: 0,
                      duration: 220.ms,
                      delay: 130.ms,
                      curve: Curves.easeOutCubic),
              loading: () => const LinearProgressIndicator()
                  .animate()
                  .fadeIn(
                      duration: 200.ms,
                      delay: 130.ms,
                      curve: Curves.easeOutCubic),
              error: (error, _) => Text(tr('expenses.form.categories_error'))
                  .animate()
                  .fadeIn(
                      duration: 200.ms,
                      delay: 130.ms,
                      curve: Curves.easeOutCubic)
                  .shake(duration: 220.ms, delay: 160.ms),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    final navigatorContext = context;
                    final picked = await showDatePicker(
                      context: navigatorContext,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDate: _date,
                    );
                    if (picked != null && mounted) {
                      setState(() => _date = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('expenses.form.date'),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat.yMMMMd(context.locale.toLanguageTag()).format(_date),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: tr('expenses.form.note'),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.note_outlined,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    size: 20,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              ),
              maxLines: 3,
            )
                .animate()
                .fadeIn(
                    duration: 200.ms,
                    delay: 180.ms,
                    curve: Curves.easeOutCubic)
                .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 220.ms,
                    delay: 180.ms,
                    curve: Curves.easeOutCubic),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _handleSubmit(ref),
              icon: const Icon(Icons.check_rounded, size: 22),
              label: Text(
                tr('expenses.form.submit'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 2,
              ),
            )
                .animate()
                .fadeIn(
                    duration: 200.ms,
                    delay: 200.ms,
                    curve: Curves.easeOutCubic)
                .scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1, 1),
                    duration: 220.ms,
                    delay: 200.ms,
                    curve: Curves.easeOutCubic),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showDeleteDialog(context, ref),
                icon: const Icon(Icons.delete),
                label: Text(tr('delete')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  void _handleSubmit(WidgetRef ref) {
    if (!_formKey.currentState!.validate()) return;

    final currencyCode = ref.read(defaultCurrencyProvider);
    final number = double.parse(_amountController.text.replaceAll(',', '.'));
    final draft = ExpenseDraft(
      amountInCents: (number * 100).round(),
      currencyCode: currencyCode,
      type: _type,
      occurredAt: _date,
      categoryId: _categoryId,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );

    ref.read(expenseFormControllerProvider.notifier).submit(
      draft,
      expenseId: _isEditing ? widget.expense!.id : null,
    );
  }

  Future<void> _scanReceipt(BuildContext context) async {
    if (_isEditing) return;

    try {
      // Запрашиваем разрешение и открываем камеру
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (image == null || !mounted) return;

      // Сохраняем context перед async операциями
      final navigatorContext = context;
      if (!mounted) return;
      
      // Показываем индикатор загрузки
      showDialog(
        context: navigatorContext,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Сканируем чек
        final scanner = ReceiptScannerService();
        final result = await scanner.scanReceipt(File(image.path));
        scanner.dispose();

        if (!mounted) return;
        Navigator.of(navigatorContext).pop(); // Закрываем индикатор загрузки

        if (result == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(navigatorContext).showSnackBar(
            SnackBar(
              content: Text(tr('expenses.form.scan_failed')),
            ),
          );
          return;
        }

        // Заполняем форму данными из чека
        setState(() {
          _amountController.text = result.amount.amount.toString();
          if (result.date != null) {
            _date = result.date!;
          }
          if (result.merchant != null && _noteController.text.isEmpty) {
            _noteController.text = result.merchant!;
          }
        });

        if (!mounted) return;
        ScaffoldMessenger.of(navigatorContext).showSnackBar(
          SnackBar(
            content: Text(tr('expenses.form.scan_success')),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.of(navigatorContext).pop(); // Закрываем индикатор загрузки
        ScaffoldMessenger.of(navigatorContext).showSnackBar(
          SnackBar(
            content: Text(tr('expenses.form.scan_error', args: [e.toString()])),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final navigatorContext = context;
      ScaffoldMessenger.of(navigatorContext).showSnackBar(
        SnackBar(
          content: Text(tr('expenses.form.camera_error', args: [e.toString()])),
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final navigatorContext = context;
    final confirmed = await showDialog<bool>(
      context: navigatorContext,
      builder: (context) => AlertDialog(
        title: Text(tr('expenses.delete.title')),
        content: Text(tr('expenses.delete.message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(expensesRepositoryProvider);
      await repo.softDelete(widget.expense!.id);
      if (mounted) {
        Navigator.of(navigatorContext).pop();
        ScaffoldMessenger.of(navigatorContext).showSnackBar(
          SnackBar(content: Text(tr('expenses.delete.success'))),
        );
      }
    }
  }
}
