import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:my_todo_app/src/rust/api/simple.dart'; // Import Rust bridge
import 'package:my_todo_app/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init(); // Initialize the bridge
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: TodoPage());
  }
}

class TodoPage extends StatefulWidget {
  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  // This list lives in Flutter memory
  List<TodoItem> _todos = [];
  String _filePath = "";

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  // Setup: Find the file path and load data from Rust
  Future<void> _initApp() async {
    final directory = await getApplicationDocumentsDirectory();
    _filePath = "${directory.path}/my_todos.json";

    // Call Rust to load data
    final loaded = await loadTodos(path: _filePath);
    setState(() {
      _todos = loaded;
    });
  }

  // Action: Add a new item
  void _addItem() {
    setState(() {
      _todos.add(TodoItem(title: "New Task ${_todos.length + 1}", isDone: false));
    });
    saveTodos(path: _filePath, items: _todos); // Tell Rust to save
  }

  // Action: Toggle a checkbox
  void _toggleItem(int index) {
    setState(() {
    //Create a copy with the new value and replace the item in the list
      _todos[index] = TodoItem(
        title: _todos[index].title,
        isDone: !_todos[index].isDone,
      );
    });
    saveTodos(path: _filePath, items: _todos); // Tell Rust to save
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rust + Flutter Todo")),
      body: ListView.builder(
        itemCount: _todos.length,
        itemBuilder: (context, index) {
          final item = _todos[index];
          return ListTile(
            title: Text(item.title),
            leading: Checkbox(
              value: item.isDone,
              onChanged: (_) => _toggleItem(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}