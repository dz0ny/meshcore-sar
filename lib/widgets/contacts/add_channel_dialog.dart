import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Bottom sheet for adding a new channel
class AddChannelSheet extends StatefulWidget {
  final Future<void> Function(String name, String secret) onCreateChannel;

  const AddChannelSheet({super.key, required this.onCreateChannel});

  @override
  State<AddChannelSheet> createState() => _AddChannelSheetState();
}

class _AddChannelSheetState extends State<AddChannelSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _secretController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  /// Validate that a string contains only ASCII characters
  bool _isAscii(String text) {
    return text.codeUnits.every((unit) => unit < 128);
  }

  /// Validate channel name
  String? _validateName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return l10n.channelNameRequired;
    }

    if (trimmedValue.length > 31) {
      return l10n.channelNameTooLong;
    }

    if (!_isAscii(trimmedValue)) {
      return l10n.invalidAsciiCharacters;
    }

    return null;
  }

  /// Validate channel secret
  String? _validateSecret(String? value) {
    final l10n = AppLocalizations.of(context)!;

    if (value == null || value.isEmpty) {
      return l10n.channelSecretRequired;
    }

    if (value.length > 32) {
      return l10n.channelSecretTooLong;
    }

    if (!_isAscii(value)) {
      return l10n.invalidAsciiCharacters;
    }

    return null;
  }

  /// Handle channel creation
  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final channelName = _nameController.text.trim();
      final isHashChannel = channelName.startsWith('#');

      // For hash channels, pass empty secret (will be auto-generated)
      // For private channels, use the provided secret
      final secret = isHashChannel ? '' : _secretController.text;

      await widget.onCreateChannel(channelName, secret);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Error is handled by parent
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final normalizedName = _nameController.text.trimLeft();
    final isHashChannel = normalizedName.startsWith('#');

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.addChannel,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isCreating
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close),
                      tooltip: l10n.close,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.channelTypesInfo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.channelName,
                    hintText: l10n.channelNameHint,
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      isHashChannel ? Icons.tag : Icons.lock_outline,
                      color: isHashChannel ? Colors.blue : Colors.orange,
                    ),
                  ),
                  enabled: !_isCreating,
                  maxLength: 31,
                  validator: _validateName,
                  textInputAction: isHashChannel
                      ? TextInputAction.done
                      : TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  onFieldSubmitted: (_) {
                    if (isHashChannel) {
                      _handleCreate();
                    }
                  },
                ),
                if (!isHashChannel) ...[
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _secretController,
                    decoration: InputDecoration(
                      labelText: l10n.channelSecret,
                      hintText: l10n.channelSecretHint,
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                    enabled: !_isCreating,
                    maxLength: 32,
                    validator: _validateSecret,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleCreate(),
                  ),
                  SizedBox(height: 8),
                  Text(
                    l10n.channelSecretHelp,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (isHashChannel) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 20,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.hashChannelInfo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isCreating
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isCreating ? null : _handleCreate,
                        child: _isCreating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.createChannel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
