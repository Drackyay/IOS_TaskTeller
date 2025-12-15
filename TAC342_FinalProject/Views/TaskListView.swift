//
//  TaskListView.swift
//  TAC342_FinalProject
//
//  Task list view with filtering, searching, and CRUD operations
//

import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var appSession: AppSessionViewModel
    @StateObject private var viewModel: TaskListViewModel
    @State private var showAddTask = false
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate: Date?
    @State private var newTaskPriority: TaskPriority = .medium
    @State private var newTaskCategory: TaskCategory = .other
    @State private var showDueDatePicker = false
    
    init(taskRepository: TaskRepository, userUID: String) {
        _viewModel = StateObject(wrappedValue: TaskListViewModel(taskRepository: taskRepository, userUID: userUID))
    }
    
    var body: some View {
        ZStack {
            Color(hex: "0f0f1a").ignoresSafeArea()
            VStack(spacing: 0) {
                filterChips.padding(.horizontal).padding(.top, 8)
                searchBar.padding()
                if viewModel.filteredTasks.isEmpty { emptyState } else { taskList }
            }
        }
        .navigationTitle("Tasks")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button { showAddTask = true } label: { Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundColor(Color(hex: "e94560")) } } }
        .sheet(isPresented: $showAddTask) { addTaskSheet }
    }
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    Button { withAnimation { viewModel.selectedFilter = filter } } label: {
                        HStack(spacing: 6) {
                            Text(filter.rawValue).font(.custom("Avenir-Medium", size: 14))
                            if let count = viewModel.filterCounts[filter], count > 0 { Text("\(count)").font(.custom("Avenir-Heavy", size: 12)).padding(.horizontal, 6).padding(.vertical, 2).background(viewModel.selectedFilter == filter ? Color.white.opacity(0.2) : Color(hex: "606060").opacity(0.3)).cornerRadius(6) }
                        }.foregroundColor(viewModel.selectedFilter == filter ? .white : Color(hex: "a0a0a0")).padding(.horizontal, 16).padding(.vertical, 10).background(viewModel.selectedFilter == filter ? Color(hex: "e94560") : Color(hex: "1a1a2e")).cornerRadius(20)
                    }
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass").foregroundColor(Color(hex: "606060"))
            TextField("Search tasks...", text: $viewModel.searchText).foregroundColor(.white)
            if !viewModel.searchText.isEmpty { Button { viewModel.searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(Color(hex: "606060")) } }
        }.padding().background(Color(hex: "1a1a2e")).cornerRadius(12)
    }
    
    private var taskList: some View {
        List {
            ForEach(viewModel.filteredTasks) { task in
                NavigationLink { TaskDetailView(task: task, taskRepository: appSession.taskRepository) } label: { TaskRowView(task: task) { Task { await viewModel.toggleCompletion(task) } } }
                .listRowBackground(Color.clear).listRowSeparator(.hidden).listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }.onDelete { indexSet in for index in indexSet { Task { await viewModel.deleteTask(viewModel.filteredTasks[index]) } } }
        }.listStyle(.plain).scrollContentBackground(.hidden)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle").font(.system(size: 60)).foregroundColor(Color(hex: "4ade80"))
            Text(viewModel.searchText.isEmpty ? "No Tasks" : "No Results").font(.custom("Avenir-Heavy", size: 20)).foregroundColor(.white)
            Text(viewModel.searchText.isEmpty ? "Tap + to add a task" : "Try a different search").font(.custom("Avenir-Regular", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
            Spacer()
        }.padding()
    }
    
    private var addTaskSheet: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0f0f1a").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task Title").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
                            TextField("What needs to be done?", text: $newTaskTitle).foregroundColor(.white).padding().background(Color(hex: "1a1a2e")).cornerRadius(12)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Due Date (Optional)").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
                            Button { showDueDatePicker.toggle() } label: {
                                HStack {
                                    Image(systemName: "calendar").foregroundColor(Color(hex: "e94560"))
                                    if let date = newTaskDueDate { Text(date, style: .date).foregroundColor(.white) } else { Text("Set due date").foregroundColor(Color(hex: "a0a0a0")) }
                                    Spacer()
                                    if newTaskDueDate != nil { Button { newTaskDueDate = nil } label: { Image(systemName: "xmark.circle.fill").foregroundColor(Color(hex: "606060")) } }
                                }.padding().background(Color(hex: "1a1a2e")).cornerRadius(12)
                            }
                            if showDueDatePicker { DatePicker("", selection: Binding(get: { newTaskDueDate ?? Date() }, set: { newTaskDueDate = $0 }), displayedComponents: [.date, .hourAndMinute]).datePickerStyle(.graphical).colorScheme(.dark).tint(Color(hex: "e94560")) }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
                            HStack(spacing: 12) {
                                ForEach(TaskPriority.allCases, id: \.self) { priority in
                                    Button { newTaskPriority = priority } label: {
                                        VStack(spacing: 4) {
                                            Circle().fill(priorityColor(priority)).frame(width: 24, height: 24)
                                            Text(priority.displayName).font(.custom("Avenir-Medium", size: 12)).foregroundColor(newTaskPriority == priority ? .white : Color(hex: "a0a0a0"))
                                        }.frame(maxWidth: .infinity).padding(.vertical, 12).background(newTaskPriority == priority ? priorityColor(priority).opacity(0.2) : Color(hex: "1a1a2e")).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(newTaskPriority == priority ? priorityColor(priority) : Color.clear, lineWidth: 2))
                                    }
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(TaskCategory.allCases, id: \.self) { category in
                                    Button { newTaskCategory = category } label: {
                                        VStack(spacing: 6) {
                                            Image(systemName: category.iconName).font(.system(size: 20))
                                            Text(category.displayName).font(.custom("Avenir-Medium", size: 11))
                                        }.foregroundColor(newTaskCategory == category ? Color(hex: "e94560") : Color(hex: "a0a0a0")).frame(maxWidth: .infinity).padding(.vertical, 12).background(newTaskCategory == category ? Color(hex: "e94560").opacity(0.1) : Color(hex: "1a1a2e")).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(newTaskCategory == category ? Color(hex: "e94560") : Color.clear, lineWidth: 2))
                                    }
                                }
                            }
                        }
                        Spacer(minLength: 40)
                    }.padding()
                }
            }
            .navigationTitle("New Task").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { resetForm(); showAddTask = false }.foregroundColor(Color(hex: "a0a0a0")) }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { Task { await viewModel.addTask(title: newTaskTitle, dueDate: newTaskDueDate, priority: newTaskPriority, category: newTaskCategory); resetForm(); showAddTask = false } }.font(.custom("Avenir-Heavy", size: 16)).foregroundColor(newTaskTitle.isEmpty ? Color(hex: "606060") : Color(hex: "e94560")).disabled(newTaskTitle.isEmpty) }
            }
        }.presentationDetents([.large])
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority { case .low: return Color(hex: "4ade80"); case .medium: return Color(hex: "fbbf24"); case .high: return Color(hex: "ff6b6b") }
    }
    
    private func resetForm() {
        newTaskTitle = ""; newTaskDueDate = nil; newTaskPriority = .medium; newTaskCategory = .other; showDueDatePicker = false
    }
}

