//
//  HomeView.swift
//  TAC342_FinalProject
//
//  Home screen showing today's tasks, calendar events, and AI summary
//

import SwiftUI
import EventKit

struct HomeView: View {
    @EnvironmentObject var appSession: AppSessionViewModel
    @StateObject private var viewModel: HomeViewModel
    
    init(taskRepository: TaskRepository) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(taskRepository: taskRepository))
    }
    
    var body: some View {
        ZStack {
            Color(hex: "0f0f1a").ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    if let summary = viewModel.dailySummary { aiSummaryCard(summary) }
                    else if viewModel.isLoadingSummary { loadingSummaryCard }
                    if !viewModel.hasCalendarAccess { calendarAccessCard }
                    if viewModel.hasCalendarAccess && !viewModel.todayEvents.isEmpty { eventsSection }
                    if !viewModel.overdueTasks.isEmpty { taskSection(title: "Overdue", icon: "exclamationmark.triangle.fill", iconColor: Color(hex: "ff6b6b"), tasks: viewModel.overdueTasks) }
                    taskSection(title: "Today", icon: "sun.max.fill", iconColor: Color(hex: "fbbf24"), tasks: viewModel.todayTasks)
                    if !viewModel.upcomingTasks.isEmpty { taskSection(title: "Upcoming", icon: "calendar", iconColor: Color(hex: "60a5fa"), tasks: Array(viewModel.upcomingTasks.prefix(5))) }
                    Spacer(minLength: 100)
                }.padding()
            }.refreshable { await viewModel.loadData() }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { NavigationLink { SettingsView() } label: { Image(systemName: "gearshape.fill").foregroundColor(Color(hex: "a0a0a0")) } } }
        .task { await viewModel.loadData() }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting).font(.custom("Avenir-Medium", size: 16)).foregroundColor(Color(hex: "a0a0a0"))
            Text(appSession.displayName).font(.custom("Avenir-Heavy", size: 28)).foregroundColor(.white)
            Text(dateString).font(.custom("Avenir-Regular", size: 14)).foregroundColor(Color(hex: "808080"))
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default: return "Good evening,"
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
    
    private func aiSummaryCard(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Image(systemName: "sparkles").foregroundColor(Color(hex: "e94560")); Text("Daily Insight").font(.custom("Avenir-Heavy", size: 16)).foregroundColor(.white) }
            Text(summary).font(.custom("Avenir-Regular", size: 15)).foregroundColor(Color(hex: "d0d0d0")).lineSpacing(4)
        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(LinearGradient(colors: [Color(hex: "1a1a2e"), Color(hex: "2a2a4a")], startPoint: .topLeading, endPoint: .bottomTrailing)).cornerRadius(16).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "e94560").opacity(0.3), lineWidth: 1))
    }
    
    private var loadingSummaryCard: some View {
        HStack(spacing: 12) {
            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "e94560")))
            Text("Generating your daily insight...").font(.custom("Avenir-Regular", size: 14)).foregroundColor(Color(hex: "a0a0a0"))
        }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color(hex: "1a1a2e")).cornerRadius(16)
    }
    
    private var calendarAccessCard: some View {
        VStack(spacing: 12) {
            HStack { Image(systemName: "calendar.badge.plus").foregroundColor(Color(hex: "60a5fa")); Text("Enable Calendar Access").font(.custom("Avenir-Heavy", size: 16)).foregroundColor(.white); Spacer() }
            Text("See your calendar events alongside your tasks").font(.custom("Avenir-Regular", size: 14)).foregroundColor(Color(hex: "a0a0a0")).frame(maxWidth: .infinity, alignment: .leading)
            Button { Task { await viewModel.requestCalendarAccess() } } label: { Text("Enable").font(.custom("Avenir-Heavy", size: 14)).foregroundColor(.white).padding(.horizontal, 24).padding(.vertical, 10).background(Color(hex: "60a5fa")).cornerRadius(8) }.frame(maxWidth: .infinity, alignment: .trailing)
        }.padding().background(Color(hex: "1a1a2e")).cornerRadius(16)
    }
    
    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { Image(systemName: "calendar").foregroundColor(Color(hex: "a78bfa")); Text("Today's Events").font(.custom("Avenir-Heavy", size: 18)).foregroundColor(.white) }
            ForEach(viewModel.todayEvents.prefix(3), id: \.eventIdentifier) { event in eventRow(event) }
        }
    }
    
    private func eventRow(_ event: EKEvent) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2).fill(Color(cgColor: event.calendar.cgColor)).frame(width: 4, height: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title ?? "Untitled").font(.custom("Avenir-Medium", size: 15)).foregroundColor(.white)
                if let start = event.startDate { Text(start, style: .time).font(.custom("Avenir-Regular", size: 13)).foregroundColor(Color(hex: "a0a0a0")) }
            }
            Spacer()
        }.padding().background(Color(hex: "1a1a2e")).cornerRadius(12)
    }
    
    private func taskSection(title: String, icon: String, iconColor: Color, tasks: [TaskItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon).foregroundColor(iconColor)
                Text(title).font(.custom("Avenir-Heavy", size: 18)).foregroundColor(.white)
                if !tasks.isEmpty { Text("\(tasks.count)").font(.custom("Avenir-Heavy", size: 12)).foregroundColor(.white).padding(.horizontal, 8).padding(.vertical, 4).background(iconColor.opacity(0.3)).cornerRadius(8) }
            }
            if tasks.isEmpty { Text("No tasks").font(.custom("Avenir-Regular", size: 14)).foregroundColor(Color(hex: "606060")).padding(.vertical, 8) }
            else {
                ForEach(tasks) { task in
                    NavigationLink { TaskDetailView(task: task, taskRepository: appSession.taskRepository) } label: { TaskRowView(task: task) { Task { await viewModel.toggleTaskCompletion(task) } } }.buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button { onToggle() } label: { Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle").font(.system(size: 22)).foregroundColor(task.isCompleted ? Color(hex: "4ade80") : Color(hex: "606060")) }
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title).font(.custom("Avenir-Medium", size: 15)).foregroundColor(task.isCompleted ? Color(hex: "606060") : .white).strikethrough(task.isCompleted)
                HStack(spacing: 8) {
                    HStack(spacing: 4) { Image(systemName: task.category.iconName).font(.system(size: 10)); Text(task.category.displayName).font(.custom("Avenir-Regular", size: 11)) }.foregroundColor(Color(hex: "a0a0a0"))
                    if let dueDate = task.dueDate { Text(formatDueDate(dueDate)).font(.custom("Avenir-Regular", size: 11)).foregroundColor(task.isOverdue ? Color(hex: "ff6b6b") : Color(hex: "a0a0a0")) }
                }
            }
            Spacer()
            Circle().fill(priorityColor).frame(width: 8, height: 8)
            Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(Color(hex: "606060"))
        }.padding().background(Color(hex: "1a1a2e")).cornerRadius(12)
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .high: return Color(hex: "ff6b6b")
        case .medium: return Color(hex: "fbbf24")
        case .low: return Color(hex: "4ade80")
        }
    }
    
    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        else if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        else { let formatter = DateFormatter(); formatter.dateFormat = "MMM d"; return formatter.string(from: date) }
    }
}

