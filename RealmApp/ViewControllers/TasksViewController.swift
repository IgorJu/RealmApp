//
//  TasksViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//

import UIKit
import RealmSwift

final class TasksViewController: UITableViewController {
    
    var taskList: TaskList!
    
    private var currentTasks: Results<Task>!
    private var completedTasks: Results<Task>!
    private let storageManager = StorageManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = taskList.title
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        navigationItem.rightBarButtonItems = [addButton, editButtonItem]
        
        currentTasks = taskList.tasks.filter("isComplete = false")
        completedTasks = taskList.tasks.filter("isComplete = true")
    }
    
    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? currentTasks.count : completedTasks.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? "CURRENT TASKS" : "COMPLETED TASKS"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TasksCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let task = indexPath.section == 0 ? currentTasks[indexPath.row] : completedTasks[indexPath.row]
        
        content.text = task.title
        content.secondaryText = task.note
        cell.contentConfiguration = content
        return cell
    }
    //MARK: - Tableview Delegate
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [unowned self] _, _, _ in
            deleteTask(at: indexPath)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { [unowned self] _, _, isDone in
            editTask(at: indexPath)
            isDone(true)
        }
        
        let doneAction = UIContextualAction(
            style: .normal,
            title: indexPath.section == 0 ? "Done" : "Undone"
        )
        { [unowned self] _, _, isDone in
            doneTask(at: indexPath)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            isDone(true)
        }
        editAction.backgroundColor = UIColor.orange
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
    
    //MARK: - Private Methods
    //MARK: - Done
    private func doneTask(at indexPath: IndexPath) {
        if indexPath.section == 0 {
            let task = currentTasks[indexPath.row]
            storageManager.doneTask(task)
        } else if indexPath.section == 1 {
            let task = completedTasks[indexPath.row]
            storageManager.doneTask(task)
        }
        
        tableView.beginUpdates()
        tableView.moveRow(
            at: indexPath,
            to: IndexPath(
                row: 0,
                section: indexPath.section == 0 ? 1 : 0
            )
        )
        tableView.endUpdates()
    }
    
    //MARK: - Edit
    private func editTask(at indexPath: IndexPath) {
        if indexPath.section == 0 {
            let task = currentTasks[indexPath.row]
            showAlert(with: task) { [weak self] in
                self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        } else {
            let task = completedTasks[indexPath.row]
            showAlert(with: task) { [weak self] in
                self?.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }
    }
    //MARK: - Delete
    private func deleteTask(at indexPath: IndexPath) {
        if indexPath.section == 0 {
            let task = currentTasks[indexPath.row]
            storageManager.deleteTask(task)
        } else if indexPath.section == 1 {
            let task = completedTasks[indexPath.row]
            storageManager.deleteTask(task)
        }
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
    
    //MARK: - Save
    private func save(task: String, withNote note: String) {
        storageManager.save(task, withNote: note, to: taskList) { task in
            let rowIndex = IndexPath(row: currentTasks.index(of: task) ?? 0, section: 0)
            tableView.insertRows(at: [rowIndex], with: .automatic)
        }
    }
    @objc private func addButtonPressed() {
        showAlert()
    }
}
    
//MARK: -  Alert
extension TasksViewController {
    private func showAlert(with task: Task? = nil, completion: (() -> Void)? = nil) {
        let alertBuilder = AlertControllerBuilder(
            title: task != nil ? "Edit Task" : "New Task",
            message: "What do you want to do?"
        )
        
        alertBuilder
            .setTextFields(title: task?.title, note: task?.note)
            .addAction(
                title: task != nil ? "Update Task" : "Save Task",
                style: .default
            ) { [weak self] taskTitle, taskNote in
                if let task, let completion {
                    self?.storageManager.editTask(task, newTitle: taskTitle, newNote: taskNote)
                    completion()
                    return
                }
                self?.save(task: taskTitle, withNote: taskNote)
            }
            .addAction(title: "Cancel", style: .destructive)
        
        let alertController = alertBuilder.build()
        present(alertController, animated: true)
    }
}

