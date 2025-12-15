//
//  TaskDetailView.swift
//  TAC342_FinalProject
//
//  Detailed task view with editing and calendar integration
//

import SwiftUI
import EventKit
import EventKitUI

struct TaskDetailView: View {
    @EnvironmentObject var appSession: AppSessionViewModel
    @StateObject private var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showDatePicker = false
    
    init(task: TaskItem, taskRepository: TaskRepository) {
        _viewModel = StateObject(wrappedValue: TaskDetailViewModel(task: task, taskRepository: taskRepository))
    }
    
    var body: some View {
        ZStack {
            Color(hex: "0f0f1a").ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    completionHeader
                    titleSection
                    dueDateSection
                    prioritySection
                    categorySection
                    notesSection
                    calendarSection
                    deleteSection
                    Spacer(minLength: 100)
                }.padding()
            }
        }
        .navigationTitle("Task Details").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { if viewModel.hasChanges { Button("Save") { Task { await viewModel.saveChanges() } }.font(.custom("Avenir-Heavy", size: 16)).foregroundColor(Color(hex: "e94560")) } } }
        .alert("Delete Task", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { Task { try? await viewModel.deleteTask(); dismiss() } }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Are you sure you want to delete this task?") }
        .sheet(isPresented: $viewModel.showEventEditor) {
            EventEditViewControllerRepresentable(eventStore: viewModel.eventStore, event: viewModel.createCalendarEvent()) { action, identifier in
                if action == .saved, let id = identifier { Task { await viewModel.handleEventSaved(eventIdentifier: id) } }
            }
        }
    }
    
    private var completionHeader: some View {
        Button { Task { await viewModel.toggleCompletion() } } label: {
            HStack(spacing: 16) {
                Image(systemName: viewModel.task.isCompleted ? "checkmark.circle.fill" : "circle").font(.system(size: 32)).foregroundColor(viewModel.task.isCompleted ? Color(hex: "4ade80") : Color(hex: "606060"))
                Text(viewModel.task.isCompleted ? "Completed" : "Mark as Complete").font(.custom("Avenir-Medium", size: 16)).foregroundColor(viewModel.task.isCompleted ? Color(hex: "4ade80") : Color(hex: "a0a0a0"))
                Spacer()
            }.padding().background(Color(hex: "1a1a2e")).cornerRadius(16)
        }
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
            TextField("Task title", text: $viewModel.task.title).font(.custom("Avenir-Medium", size: 18)).foregroundColor(.white).padding().background(Color(hex: "1a1a2e")).cornerRadius(12)
        }
    }
    
    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Due Date").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
            Button { showDatePicker.toggle() } label: {
                HStack {
                    Image(systemName: "calendar").foregroundColor(Color(hex: "e94560"))
                    if let date = viewModel.task.dueDate { Text(date, style: .date).foregroundColor(.white); Text(date, style: .time).foregroundColor(Color(hex: "a0a0a0")) }
                    else { Text("No due date").foregroundColor(Color(hex: "606060")) }
                    Spacer()
                    if viewModel.task.dueDate != nil { Button { viewModel.task.dueDate = nil } label: { Image(systemName: "xmark.circle.fill").foregroundColor(Color(hex: "606060")) } }
                }.padding().background(Color(hex: "1a1a2e")).cornerRadius(12)
            }
            if showDatePicker {
                DatePicker("", selection: Binding(get: { viewModel.task.dueDate ?? Date() }, set: { viewModel.task.dueDate = $0 }), displayedComponents: [.date, .hourAndMinute]).datePickerStyle(.graphical).colorScheme(.dark).tint(Color(hex: "e94560")).padding().background(Color(hex: "1a1a2e")).cornerRadius(12)
            }
        }
    }
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Priority").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
            HStack(spacing: 12) {
                ForEach(TaskPriority.allCases, id: \.self) { priority in
                    Button { viewModel.task.priority = priority } label: {
                        VStack(spacing: 4) {
                            Circle().fill(priorityColor(priority)).frame(width: 24, height: 24)
                            Text(priority.displayName).font(.custom("Avenir-Medium", size: 12)).foregroundColor(viewModel.task.priority == priority ? .white : Color(hex: "a0a0a0"))
                        }.frame(maxWidth: .infinity).padding(.vertical, 12).background(viewModel.task.priority == priority ? priorityColor(priority).opacity(0.2) : Color(hex: "1a1a2e")).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(viewModel.task.priority == priority ? priorityColor(priority) : Color.clear, lineWidth: 2))
                    }
                }
            }
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(TaskCategory.allCases, id: \.self) { category in
                    Button { viewModel.task.category = category } label: {
                        VStack(spacing: 6) {
                            Image(systemName: category.iconName).font(.system(size: 20))
                            Text(category.displayName).font(.custom("Avenir-Medium", size: 11))
                        }.foregroundColor(viewModel.task.category == category ? Color(hex: "e94560") : Color(hex: "a0a0a0")).frame(maxWidth: .infinity).padding(.vertical, 12).background(viewModel.task.category == category ? Color(hex: "e94560").opacity(0.1) : Color(hex: "1a1a2e")).cornerRadius(12).overlay(RoundedRectangle(cornerRadius: 12).stroke(viewModel.task.category == category ? Color(hex: "e94560") : Color.clear, lineWidth: 2))
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
            TextEditor(text: Binding(get: { viewModel.task.notes ?? "" }, set: { viewModel.task.notes = $0.isEmpty ? nil : $0 })).font(.custom("Avenir-Regular", size: 15)).foregroundColor(.white).scrollContentBackground(.hidden).frame(minHeight: 100).padding().background(Color(hex: "1a1a2e")).cornerRadius(12)
        }
    }
    
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calendar").font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
            if viewModel.hasCalendarEvent {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Color(hex: "4ade80"))
                    Text("Added to Calendar").font(.custom("Avenir-Medium", size: 15)).foregroundColor(.white)
                    Spacer()
                    Button("Remove") { Task { await viewModel.unlinkCalendarEvent() } }.font(.custom("Avenir-Medium", size: 14)).foregroundColor(Color(hex: "ff6b6b"))
                }.padding().background(Color(hex: "1a1a2e")).cornerRadius(12)
            } else if viewModel.hasCalendarAccess {
                Button { viewModel.showEventEditor = true } label: {
                    HStack {
                        Image(systemName: "calendar.badge.plus").foregroundColor(Color(hex: "60a5fa"))
                        Text("Add to Calendar").font(.custom("Avenir-Medium", size: 15)).foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(Color(hex: "606060"))
                    }.padding().background(Color(hex: "1a1a2e")).cornerRadius(12)
                }
            } else {
                Button { Task { await viewModel.requestCalendarAccess() } } label: {
                    HStack {
                        Image(systemName: "calendar").foregroundColor(Color(hex: "60a5fa"))
                        Text("Enable Calendar Access").font(.custom("Avenir-Medium", size: 15)).foregroundColor(.white)
                        Spacer()
                    }.padding().background(Color(hex: "1a1a2e")).cornerRadius(12)
                }
            }
        }
    }
    
    private var deleteSection: some View {
        Button { showDeleteConfirmation = true } label: {
            HStack { Image(systemName: "trash"); Text("Delete Task") }.font(.custom("Avenir-Medium", size: 16)).foregroundColor(Color(hex: "ff6b6b")).frame(maxWidth: .infinity).padding().background(Color(hex: "ff6b6b").opacity(0.1)).cornerRadius(12)
        }.padding(.top, 16)
    }
    
    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority { case .low: return Color(hex: "4ade80"); case .medium: return Color(hex: "fbbf24"); case .high: return Color(hex: "ff6b6b") }
    }
}

