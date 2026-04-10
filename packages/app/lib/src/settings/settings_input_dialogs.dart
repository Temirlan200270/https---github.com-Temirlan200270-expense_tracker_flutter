import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_constants.dart';
import 'settings_providers.dart';

Future<void> showGeminiApiKeyEditor(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => const _GeminiApiKeyDialog(),
  );
}

class _GeminiApiKeyDialog extends ConsumerStatefulWidget {
  const _GeminiApiKeyDialog();

  @override
  ConsumerState<_GeminiApiKeyDialog> createState() => _GeminiApiKeyDialogState();
}

class _GeminiApiKeyDialogState extends ConsumerState<_GeminiApiKeyDialog> {
  late final TextEditingController _controller;
  late final bool _hadSavedKey;

  @override
  void initState() {
    super.initState();
    final String? initial = ref.read(geminiApiKeyProvider);
    _hadSavedKey = initial != null;
    _controller = TextEditingController(text: initial ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('gemini_api_key')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('gemini_api_key_description')),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: tr('gemini_api_key'),
              hintText: tr('gemini_api_key_placeholder'),
              border: const OutlineInputBorder(),
            ),
            obscureText: true,
            autocorrect: false,
          ),
          const SizedBox(height: 8),
          Text(
            tr('gemini_api_key_hint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('cancel')),
        ),
        if (_hadSavedKey)
          TextButton(
            onPressed: () async {
              await ref.read(geminiApiKeyProvider.notifier).setApiKey(null);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(tr('delete')),
          ),
        TextButton(
          onPressed: () async {
            final String newKey = _controller.text.trim();
            await ref
                .read(geminiApiKeyProvider.notifier)
                .setApiKey(newKey.isEmpty ? null : newKey);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(tr('save')),
        ),
      ],
    );
  }
}

Future<void> showExchangeRateApiKeyEditor(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => const _ExchangeRateApiKeyDialog(),
  );
}

class _ExchangeRateApiKeyDialog extends ConsumerStatefulWidget {
  const _ExchangeRateApiKeyDialog();

  @override
  ConsumerState<_ExchangeRateApiKeyDialog> createState() =>
      _ExchangeRateApiKeyDialogState();
}

class _ExchangeRateApiKeyDialogState extends ConsumerState<_ExchangeRateApiKeyDialog> {
  late final TextEditingController _controller;
  late final bool _hadSavedKey;

  @override
  void initState() {
    super.initState();
    final String? initial = ref.read(exchangeRateApiKeyProvider);
    _hadSavedKey = initial != null;
    _controller = TextEditingController(text: initial ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('exchange_rate_api_key')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('exchange_rate_api_key_description')),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: tr('exchange_rate_api_key'),
              hintText: tr('exchange_rate_api_key_placeholder'),
              border: const OutlineInputBorder(),
            ),
            obscureText: false,
            autocorrect: false,
          ),
          const SizedBox(height: 8),
          Text(
            tr('exchange_rate_api_key_hint'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('cancel')),
        ),
        if (_hadSavedKey)
          TextButton(
            onPressed: () async {
              await ref
                  .read(exchangeRateApiKeyProvider.notifier)
                  .setApiKey(null);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(tr('delete')),
          ),
        TextButton(
          onPressed: () async {
            final String newKey = _controller.text.trim();
            await ref
                .read(exchangeRateApiKeyProvider.notifier)
                .setApiKey(newKey.isEmpty ? null : newKey);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(tr('save')),
        ),
      ],
    );
  }
}

Future<void> showGeminiModelEditor(BuildContext context, WidgetRef ref) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => const _GeminiModelDialog(),
  );
}

class _GeminiModelDialog extends ConsumerStatefulWidget {
  const _GeminiModelDialog();

  @override
  ConsumerState<_GeminiModelDialog> createState() => _GeminiModelDialogState();
}

class _GeminiModelDialogState extends ConsumerState<_GeminiModelDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final String current = ref.read(geminiModelProvider);
    _controller = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(tr('gemini_model')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('gemini_model_description')),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: tr('gemini_model'),
              hintText: GeminiModelIds.defaultId,
              border: const OutlineInputBorder(),
              helperText: tr('gemini_model_hint'),
            ),
            autocorrect: false,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GeminiModelIds.suggestedIds
                .map(
                  (String id) => _GeminiModelChip(
                    modelId: id,
                    onSelect: () {
                      _controller.text = id;
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('cancel')),
        ),
        TextButton(
          onPressed: () async {
            final String newModel = _controller.text.trim();
            await ref.read(geminiModelProvider.notifier).setModel(
                  newModel.isEmpty ? GeminiModelIds.defaultId : newModel,
                );
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(tr('save')),
        ),
      ],
    );
  }
}

class _GeminiModelChip extends StatelessWidget {
  const _GeminiModelChip({
    required this.modelId,
    required this.onSelect,
  });

  final String modelId;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(modelId),
      onPressed: onSelect,
    );
  }
}
