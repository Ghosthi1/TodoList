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
  Future<void> _addItem(Map<String,String> newEntry) async{
    final String title = newEntry['title'] ?? "";
    final String description = newEntry['description'] ?? "";
    final String date = newEntry['date'] ?? "";

    final updatedList = await addTodo(path: _filePath, items: _todos, title: title, description: description, date: date);

      setState(() {
        _todos = updatedList;
      });
  }

  // Action:: remove item
  Future<void> _removeItem(int index) async {
    final updatedList = await removeTodo(path: _filePath, items: _todos, index: BigInt.from(index));
    setState(() {
      _todos = updatedList;
    });
  }

  // Action: Toggle a checkbox
  void _toggleItem(int index) {
    setState(() {
    //Create a copy with the new value and replace the item in the list
      _todos[index] = TodoItem(
        title: _todos[index].title,
        description: _todos[index].description,
        date: _todos[index].date,
        isDone: !_todos[index].isDone,
      );
    });
    saveTodos(path: _filePath, items: _todos); // Tell Rust to save

  }

  Future<void> _editItem(int index, Map<String, String> updatedEntry) async {
    setState(() {
      _todos[index] = TodoItem(
        title: updatedEntry['title'] ?? _todos[index].title,
        description: updatedEntry['description'] ?? _todos[index].description,
        date: updatedEntry['date'] ?? _todos[index].date,
        isDone: _todos[index].isDone,
      );
    });
    // Save the updated list to the file via Rust
    await saveTodos(path: _filePath, items: _todos);
  }

  // Dialog box for adding a new item
  Future<Map<String, String>?> _showAddDialog() async {
    TextEditingController controller = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    TextEditingController dateController = TextEditingController();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create a Task"),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: "Task Name"),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a task name";
                  }
                  return null;
                },
              ),

          const SizedBox(height: 10),

          TextFormField(
            controller: descriptionController,
              decoration: const InputDecoration(hintText: "Task Description"),
          ),

          TextFormField(
            controller: dateController,
            readOnly: true,
            decoration: const InputDecoration(hintText: "Task Date"),
            validator: (value) => value == null || value.isEmpty ? "Please select a date" : null,
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                String formattedDate = "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
                dateController.text = formattedDate;
              } else {
                print("Date is not selected");
              }
            }
          )
        ],
      ),
    ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, null);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.pop(context, {
                  'title': controller.text,
                  'description': descriptionController.text,
                  'date': dateController.text,
                });
              }
            },
            child: const Text("Add"),
          ),
        ],

      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rust + Flutter Todo List")),
      body: ListView.builder(
        itemCount: _todos.length,
        itemBuilder: (context, index) {
          final item = _todos[index];
          return ListTile(
            title: Text(item.title),
            subtitle: Text(item.description),
            leading: Checkbox(
              value: item.isDone,
              onChanged: (_) => _toggleItem(index),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.date,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    final updatedEntry = await _showAddDialog();
                    if (updatedEntry != null) {
                      await _editItem(index, updatedEntry);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Map<String, String>? newEntry = await _showAddDialog();
          if (newEntry != null && newEntry['title']?.isNotEmpty == true) {
            await _addItem(newEntry);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}