// lib/src/screens/tabs/exercise/widgets/qa_mini.dart
import 'package:material_ui/material_ui.dart';
import 'package:rxget/rxget.dart';
import 'package:yourfit/src/services/index.dart';
import 'package:yourfit/src/utils/objects/constants/exercise/response_schema.dart';

class QaMiniButton extends StatelessWidget {
  const QaMiniButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Material(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: () => _openSheet(context),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.question_answer, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Q&A',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _QaMiniSheet(),
    );
  }
}

class _QaMiniSheet extends StatefulWidget {
  const _QaMiniSheet();

  @override
  State<_QaMiniSheet> createState() => _QaMiniSheetState();
}

class _QaMiniSheetState extends State<_QaMiniSheet> {
  final _controller = TextEditingController();
  final _service = Get.find<ExerciseService>();
  final currentUser = Get.find<AuthService>().currentUser;
  final _items = <_QaItem>[];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final q = _controller.text.trim();
    if (q.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _items.insert(0, _QaItem(q: q, a: null, ts: DateTime.now()));
      _controller.clear();
    });

    String ans;
    try {
      final result = await _service.invokeWithUser(
        currentUser.value,
        q,
        responseSchema: ResponseSchema.answer,
      );
      if (result == null) return;
      ans = (result["answer"] as String).trim();
      if (ans.length > 1200) ans = ans.substring(0, 1200);
    } catch (e) {
      ans = 'Could not answer right now: $e';
    }

    setState(() {
      _sending = false;
      _items[0] = _items[0].copyWith(a: ans);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Ask YourFit AI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (_sending)
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      maxLines: 1,
                      decoration: InputDecoration(
                        hintText: 'e.g., “How many sets for squats?”',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _items.isEmpty
                  ? const _EmptyHint()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _QaTile(item: _items[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: 0.7,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Quick, small answers on form, sets, substitutions, etc.\nKeep it simple.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
    );
  }
}

class _QaTile extends StatelessWidget {
  const _QaTile({required this.item});
  final _QaItem item;

  @override
  Widget build(BuildContext context) {
    final a = item.a ?? '…';
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.q, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          SelectableText(a, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _QaItem {
  final String q;
  final String? a;
  final DateTime ts;
  const _QaItem({required this.q, required this.a, required this.ts});

  _QaItem copyWith({String? a}) => _QaItem(q: q, a: a ?? this.a, ts: ts);
}
