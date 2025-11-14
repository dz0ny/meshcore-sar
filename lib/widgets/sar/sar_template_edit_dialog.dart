import 'package:flutter/material.dart';
import '../../models/sar_template.dart';
import '../../l10n/app_localizations.dart';

/// Dialog for adding or editing SAR templates
class SarTemplateEditDialog extends StatefulWidget {
  final SarTemplate? template; // Null for new template
  final Function(SarTemplate) onSave;

  const SarTemplateEditDialog({
    super.key,
    this.template,
    required this.onSave,
  });

  @override
  State<SarTemplateEditDialog> createState() => _SarTemplateEditDialogState();
}

class _SarTemplateEditDialogState extends State<SarTemplateEditDialog> {
  late TextEditingController _emojiController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedColor;

  final List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Green', 'hex': '#4CAF50'},
    {'name': 'Red', 'hex': '#F44336'},
    {'name': 'Orange', 'hex': '#FF9800'},
    {'name': 'Purple', 'hex': '#9C27B0'},
    {'name': 'Blue', 'hex': '#2196F3'},
    {'name': 'Yellow', 'hex': '#FFC107'},
    {'name': 'Brown', 'hex': '#795548'},
    {'name': 'Gray', 'hex': '#9E9E9E'},
  ];

  String? _emojiError;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _emojiController = TextEditingController(text: widget.template?.emoji ?? '');
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _descriptionController = TextEditingController(text: widget.template?.description ?? '');
    _selectedColor = widget.template?.colorHex ?? '#4CAF50';
  }

  @override
  void dispose() {
    _emojiController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _validate() {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _emojiError = null;
      _nameError = null;
    });

    bool isValid = true;

    if (_emojiController.text.trim().isEmpty) {
      setState(() {
        _emojiError = l10n.emojiRequired;
      });
      isValid = false;
    }

    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _nameError = l10n.nameRequired;
      });
      isValid = false;
    }

    return isValid;
  }

  void _save() {
    if (!_validate()) return;

    final template = SarTemplate(
      id: widget.template?.id ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      emoji: _emojiController.text.trim(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      colorHex: _selectedColor,
      isDefault: widget.template?.isDefault ?? false,
    );

    widget.onSave(template);
    Navigator.of(context).pop();
  }

  String _getPreview() {
    final emoji = _emojiController.text.trim();
    final description = _descriptionController.text.trim();
    if (emoji.isEmpty) return 'S::0,0';
    if (description.isEmpty) return 'S:$emoji:0,0';
    return 'S:$emoji:0,0:$description';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                // Header
                Text(
                  widget.template == null ? l10n.addTemplate : l10n.editTemplate,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),

                // Emoji field
                TextField(
                  controller: _emojiController,
                  decoration: InputDecoration(
                    labelText: l10n.templateEmoji,
                    hintText: '🧑',
                    errorText: _emojiError,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.emoji_emotions),
                  ),
                  maxLength: 4,
                  style: const TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Name field
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.templateName,
                    hintText: l10n.templateNameHint,
                    errorText: _nameError,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.label),
                  ),
                  maxLength: 30,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Description field
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: l10n.templateDescription,
                    hintText: l10n.templateDescriptionHint,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLength: 100,
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Color picker
                Text(
                  l10n.templateColor,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _colorOptions.map((colorOption) {
                    final hex = colorOption['hex'] as String;
                    final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                    final isSelected = _selectedColor == hex;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = hex),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? colorScheme.primary : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.previewFormat,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getPreview(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: Text(l10n.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }
}
