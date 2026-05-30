import 'package:flutter/material.dart';

import 'event_input_controller.dart';
import 'event_input_style.dart';
import 'widgets/event_detail_pager.dart';
import 'widgets/event_input_actions.dart';
import 'widgets/input_text_box.dart';

class EventInputScreen extends StatefulWidget {
  const EventInputScreen({super.key});

  @override
  State<EventInputScreen> createState() => _EventInputScreenState();
}

class _EventInputScreenState extends State<EventInputScreen> {
  final _controller = EventInputController();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _controller.loadExistingEvents();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _controller.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _controller.requestParseAfterInputSettled();
    }
  }

  void _dismissKeyboardAndParse() {
    FocusScope.of(context).unfocus();
    _controller.requestParseAfterInputSettled();
  }

  Future<void> _deleteDraft(int draftIndex) async {
    final deleted = await _controller.deleteDraft(draftIndex);
    if (!mounted || !deleted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已删除事件')));
  }

  void _showVoiceComingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('AI语音输入即将上线')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EventInputStyle.background,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboardAndParse,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final metrics = EventInputMetrics.forWidth(constraints.maxWidth);
              final contentWidth = metrics.contentWidthFor(
                constraints.maxWidth,
              );

              return EventInputLayoutScope(
                metrics: metrics,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: contentWidth,
                    height: constraints.maxHeight,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final state = _controller.state;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _NavigationHeader(
                              onBack: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  metrics.horizontalPadding,
                                  metrics.isCompact ? 4 : 8,
                                  metrics.horizontalPadding,
                                  0,
                                ),
                                child: Column(
                                  children: [
                                    InputTextBox(
                                      controller: _textController,
                                      focusNode: _focusNode,
                                      parsing: state.parsing,
                                      onChanged: _controller.updateInputText,
                                      onSubmitted: _controller
                                          .requestParseAfterInputSettled,
                                      onParseNow: _controller.parseInputNow,
                                    ),
                                    if (state.errorText != null) ...[
                                      SizedBox(
                                        height: metrics.isCompact ? 8 : 12,
                                      ),
                                      _InputErrorBanner(
                                        text: state.errorText!,
                                        canRetry:
                                            state.failed &&
                                            state.inputText.trim().isNotEmpty,
                                        onRetry: _controller.parseInputNow,
                                      ),
                                    ],
                                    SizedBox(
                                      height: metrics.isCompact ? 12 : 16,
                                    ),
                                    Expanded(
                                      child: EventDetailPager(
                                        state: state,
                                        onDeleteDraft: _deleteDraft,
                                        onResetDraft:
                                            _controller.resetAiSuggestion,
                                        onTitleChanged: _controller.updateTitle,
                                        onSummaryChanged:
                                            _controller.updateSummary,
                                        onPurposeChanged:
                                            _controller.updatePurpose,
                                        onStepDescriptionChanged:
                                            _controller.updateStepDescription,
                                        onStepMinutesChanged:
                                            _controller.updateStepMinutes,
                                        onAddStep: _controller.addStep,
                                        onRemoveStep: _controller.removeStep,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                metrics.horizontalPadding,
                                metrics.isCompact ? 8 : 10,
                                metrics.horizontalPadding,
                                metrics.bottomPadding,
                              ),
                              child: EventInputActions(
                                onAddCustomEvent: _controller.addCustomEvent,
                                onVoiceInput: _showVoiceComingSoon,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavigationHeader extends StatelessWidget {
  const _NavigationHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);
    return SizedBox(
      height: metrics.navHeight,
      child: Row(
        children: [
          SizedBox(width: metrics.navLeadingGap),
          IconButton(
            tooltip: '返回',
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: EventInputStyle.accent,
              size: metrics.navIconSize,
            ),
          ),
          SizedBox(width: metrics.isCompact ? 0 : 2),
          Text(
            '安排',
            style: TextStyle(
              color: EventInputStyle.textPrimary,
              fontSize: metrics.navTitleSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputErrorBanner extends StatelessWidget {
  const _InputErrorBanner({
    required this.text,
    required this.canRetry,
    required this.onRetry,
  });

  final String text;
  final bool canRetry;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
            ),
          ),
          if (canRetry) TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
