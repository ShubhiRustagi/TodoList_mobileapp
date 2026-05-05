import 'package:flutter/material.dart';

void main() {
  runApp(const ToDoApp());
}

// ── Model ────────────────────────────────────────────────────────────────────

class Task {
  final int id; // unique, stable identity — fixes Dismissible key bug
  String title;
  bool isDone;

  Task({required this.id, required this.title, this.isDone = false});
}

// ── App ──────────────────────────────────────────────────────────────────────

class ToDoApp extends StatelessWidget {
  const ToDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F6FF),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF7BB8F5),
          surface: Color(0xFFFFFFFF),
        ),
        fontFamily: 'monospace',
      ),
      home: const HomePage(),
    );
  }
}

// ── Home Page ────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Task> _tasks = [];
  final TextEditingController _controller = TextEditingController();

  // Key stored as a field — fixes AnimatedList rebuild bug
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  int _nextId = 0; // stable unique IDs — fixes Dismissible key bug

  int get _doneCount => _tasks.where((t) => t.isDone).length;

  // ── Pastel blue palette ──────────────────────────────────────────────────
  static const Color kBg = Color(0xFFF0F6FF);
  static const Color kCard = Color(0xFFFFFFFF);
  static const Color kAccent = Color(0xFF7BB8F5);
  static const Color kAccentSoft = Color(0xFFB8D8FC);
  static const Color kAccentDark = Color(0xFF4A90D9);
  static const Color kStar = Color(0xFFFFD166); // warm star against cool blue
  static const Color kDelete = Color(0xFFFF8FAB);
  static const Color kText = Color(0xFF1E3A5F);
  static const Color kSubtext = Color(0xFF7A9CC0);

  // ── Task ops ─────────────────────────────────────────────────────────────

  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final task = Task(id: _nextId++, title: text);
    final insertIndex = _tasks.length;
    setState(() {
      _tasks.add(task);
      _controller.clear();
    });
    _listKey.currentState?.insertItem(
      insertIndex,
      duration: const Duration(milliseconds: 350),
    );
  }

  void _deleteTask(int index, {bool animated = true}) {
    if (index < 0 || index >= _tasks.length) return;
    final removed = _tasks[index];

    if (animated) {
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildAnimatedTile(removed, index, animation),
        duration: const Duration(milliseconds: 300),
      );
    }

    setState(() => _tasks.removeAt(index));

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          '"${removed.title}" removed',
          style: const TextStyle(color: kText, fontWeight: FontWeight.w500),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: kAccentDark,
          onPressed: () {
            // Re-insert at original position (clamped for safety)
            final safeIndex = index.clamp(0, _tasks.length);
            setState(() => _tasks.insert(safeIndex, removed));
            _listKey.currentState?.insertItem(
              safeIndex,
              duration: const Duration(milliseconds: 300),
            );
          },
        ),
      ),
    );
  }

  void _toggleTask(int index) {
    setState(() => _tasks[index].isDone = !_tasks[index].isDone);
  }

  // ── Bottom sheet — uses its own context for Navigator.pop ────────────────

  void _showAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        // sheetContext is the bottom sheet's own context — safe to pop
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 28,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle pill
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kAccentSoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'New Task',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kText,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  _addTask();
                  Navigator.pop(sheetContext); // uses sheet's own context ✓
                },
                style: const TextStyle(color: kText),
                cursorColor: kAccent,
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  hintStyle: const TextStyle(color: kSubtext),
                  filled: true,
                  fillColor: kBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: kAccent, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.edit_note_rounded,
                    color: kAccent,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _addTask();
                    Navigator.pop(sheetContext); // uses sheet's own context ✓
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Add Task',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: kAccentSoft,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: kStar,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'My Tasks',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: kText,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _tasks.isEmpty
                        ? 'Nothing here yet ✨'
                        : '$_doneCount of ${_tasks.length} completed',
                    style: const TextStyle(fontSize: 14, color: kSubtext),
                  ),
                  const SizedBox(height: 14),
                  if (_tasks.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _doneCount / _tasks.length,
                        backgroundColor: kAccentSoft,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          kAccentDark,
                        ),
                        minHeight: 7,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Task list ─────────────────────────────────────────────────
            Expanded(
              child: _tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: kAccentSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_outline_rounded,
                              size: 44,
                              color: kAccent,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'No tasks yet.\nTap + to get started.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: kSubtext,
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    )
                  : AnimatedList(
                      key:
                          _listKey, // stored field — not recreated on rebuild ✓
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      initialItemCount: _tasks.length,
                      itemBuilder: (context, index, animation) {
                        if (index >= _tasks.length) return const SizedBox();
                        return _buildAnimatedTile(
                          _tasks[index],
                          index,
                          animation,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }

  // ── Tile builders ────────────────────────────────────────────────────────

  Widget _buildAnimatedTile(Task task, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
      child: FadeTransition(
        opacity: animation,
        child: _buildTaskTile(task, index),
      ),
    );
  }

  Widget _buildTaskTile(Task task, int index) {
    return Dismissible(
      key: ValueKey(task.id), // stable unique ID — not title+index ✓
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteTask(index, animated: false),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kDelete.withOpacity(0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: kDelete.withOpacity(0.8),
          size: 24,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: task.isDone ? kAccentSoft : const Color(0xFFDDEAF8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: kAccent.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: GestureDetector(
            onTap: () => _toggleTask(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.isDone
                    ? kStar.withOpacity(0.15)
                    : Colors.transparent,
                border: Border.all(
                  color: task.isDone ? kStar : kAccentSoft,
                  width: 2,
                ),
              ),
              // ── Star icon instead of check ──────────────────────────
              child: Icon(
                task.isDone ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 18,
                color: task.isDone ? kStar : kAccentSoft,
              ),
            ),
          ),
          title: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: task.isDone ? kSubtext : kText,
              fontSize: 15,
              fontWeight: task.isDone ? FontWeight.normal : FontWeight.w600,
              decoration: task.isDone ? TextDecoration.lineThrough : null,
              decorationColor: kSubtext,
            ),
            child: Text(task.title),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: kDelete.withOpacity(0.5),
              size: 20,
            ),
            onPressed: () => _deleteTask(index),
          ),
        ),
      ),
    );
  }
}
