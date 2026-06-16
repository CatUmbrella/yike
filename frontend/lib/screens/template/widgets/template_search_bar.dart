import 'package:flutter/material.dart';

import '../template_style.dart';
import 'template_keyboard_dismiss.dart';

class TemplateSearchBar extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const TemplateSearchBar({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<TemplateSearchBar> createState() => _TemplateSearchBarState();
}

class _TemplateSearchBarState extends State<TemplateSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant TemplateSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      onTapOutside: (_) => dismissTemplateKeyboard(),
      onTap: () => ensureTemplateInputVisible(context),
      scrollPadding: templateInputScrollPadding(context),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 22,
          color: Color(0xFF7B8494),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 42,
          minHeight: 40,
        ),
        suffixIcon: widget.value.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                visualDensity: VisualDensity.compact,
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        hintText: '搜索模板',
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF9AA2AF),
        ),
        filled: true,
        fillColor: TemplateStyle.searchFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: TemplateStyle.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: TemplateStyle.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: TemplateStyle.accent),
        ),
      ),
    );
  }
}
