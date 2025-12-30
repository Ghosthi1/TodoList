use std::fs;
use serde::{Serialize, Deserialize};

// 1. The Data Shape
#[derive(Serialize, Deserialize, Clone)]
pub struct TodoItem {
    pub title: String,
    pub description: String,
    pub is_done: bool,
}

// 2. Load Function (Reads JSON from disk)
pub fn load_todos(path: String) -> Vec<TodoItem> {
    if let Ok(content) = fs::read_to_string(&path) {
        serde_json::from_str(&content).unwrap_or(Vec::new())
    } else {
        Vec::new() // Return empty list if file doesn't exist
    }
}

// 3. Save Function (Writes JSON to disk)
pub fn save_todos(path: String, items: Vec<TodoItem>) {
    // Convert list to pretty JSON string
    if let Ok(json) = serde_json::to_string_pretty(&items) {
        let _ = fs::write(path, json);
    }
}

pub fn add_todo(path: String, mut items: Vec<TodoItem>, title: String, description: String) -> Vec<TodoItem> {
    items.push(TodoItem {
        title,
        description,
        is_done: false
    });
    save_todos(path, items.clone());
    items
}

pub fn remove_todo(path: String,mut items: Vec<TodoItem>, index: usize ) -> Vec<TodoItem> {
    if index < items.len() {
        items.remove(index);
        save_todos(path, items.clone());
    }
    items
}

