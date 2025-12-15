//
//  OpenAIService.swift
//  TAC342_FinalProject
//
//  Service for interacting with OpenAI API
//  Supports parsing multiple tasks from natural language
//

import Foundation

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case networkError(String)
    case rateLimited
    case invalidJSON
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "OpenAI API key not configured."
        case .invalidResponse: return "Invalid response from OpenAI API"
        case .networkError(let message): return "Network error: \(message)"
        case .rateLimited: return "API rate limit reached."
        case .invalidJSON: return "Could not parse AI response"
        }
    }
}

class OpenAIService {
    static let shared = OpenAIService()
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-3.5-turbo"
    private init() {}
    
    /// Parse natural language into multiple tasks
    func parseMultipleTasks(from text: String) async throws -> [ParsedTask] {
        guard let apiKey = OpenAIConfig.apiKey else { throw OpenAIError.missingAPIKey }
        
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        let todayString = formatter.string(from: today)
        
        let systemPrompt = """
        You are a task parser. Extract ALL tasks from the user's input. The user may mention multiple tasks in one sentence.
        Today's date is \(todayString).
        
        Return a JSON object with a "tasks" array containing each task. Each task should have:
        - title: string (clear, concise task description)
        - dueDate: string or null (in "MMMM d, yyyy" format like "December 11, 2025", or "tomorrow")
        - dueTime: string or null (like "4 PM", "6 PM", "16:00")
        - priority: string ("low", "medium", or "high" - use "high" for exams, deadlines, urgent items)
        - category: string ("work", "personal", "school", "health", "shopping", or "other")
        - notes: string or null
        
        IMPORTANT: 
        - If the user mentions multiple distinct tasks/events, create SEPARATE task objects for each one
        - "tomorrow" means \(formatter.string(from: Calendar.current.date(byAdding: .day, value: 1, to: today)!))
        - Exams and tests should be "school" category and "high" priority
        
        Example input: "I have a math exam tomorrow at 4 PM and English exam on December 11 at 6 PM"
        Example output: {"tasks": [{"title": "Math exam", "dueDate": "December 11, 2025", "dueTime": "4 PM", "priority": "high", "category": "school", "notes": null}, {"title": "English exam", "dueDate": "December 11, 2025", "dueTime": "6 PM", "priority": "high", "category": "school", "notes": null}]}
        
        Return ONLY valid JSON, no additional text.
        """
        
        let response = try await makeAPIRequest(systemPrompt: systemPrompt, userMessage: "Parse these tasks: \(text)", apiKey: apiKey)
        
        // Clean up the response - remove markdown code blocks if present
        var cleanedResponse = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = cleanedResponse.data(using: .utf8) else { throw OpenAIError.invalidJSON }
        
        do {
            // Try parsing as multi-task response
            let multiResponse = try JSONDecoder().decode(ParsedTask.OpenAIMultiTaskResponse.self, from: jsonData)
            // ParsedTask.init(from:) now handles combining date + time correctly
            return multiResponse.tasks.map { ParsedTask(from: $0) }
        } catch {
            // Fallback: try parsing as single task
            do {
                let singleResponse = try JSONDecoder().decode(ParsedTask.OpenAITaskResponse.self, from: jsonData)
                return [ParsedTask(from: singleResponse)]
            } catch {
                // Last resort: create a single task with the original text
                print("JSON parsing failed: \(error)")
                return [ParsedTask(title: text)]
            }
        }
    }
    
    /// Parse single task (kept for backwards compatibility)
    func parseTask(from text: String) async throws -> ParsedTask {
        let tasks = try await parseMultipleTasks(from: text)
        return tasks.first ?? ParsedTask(title: text)
    }
    
    func generateDailySummary(tasks: [TaskItem], eventCount: Int) async throws -> String {
        guard let apiKey = OpenAIConfig.apiKey else { throw OpenAIError.missingAPIKey }
        
        let taskDescriptions = tasks.prefix(5).map { "- \($0.title) (priority: \($0.priority.displayName))" }.joined(separator: "\n")
        let systemPrompt = "You are a friendly productivity assistant. Generate a brief, encouraging daily summary (2-3 sentences max). Be concise and positive."
        let userMessage = "Today I have \(tasks.count) task(s) and \(eventCount) calendar event(s). \(tasks.isEmpty ? "No specific tasks yet." : "My tasks:\n\(taskDescriptions)")"
        
        return try await makeAPIRequest(systemPrompt: systemPrompt, userMessage: userMessage, apiKey: apiKey)
    }
    
    private func makeAPIRequest(systemPrompt: String, userMessage: String, apiKey: String) async throws -> String {
        guard let url = URL(string: apiURL) else { throw OpenAIError.networkError("Invalid URL") }
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [["role": "system", "content": systemPrompt], ["role": "user", "content": userMessage]],
            "max_tokens": 500,
            "temperature": 0.3
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw OpenAIError.invalidResponse }
        if httpResponse.statusCode == 429 { throw OpenAIError.rateLimited }
        guard httpResponse.statusCode == 200 else { throw OpenAIError.networkError("Status \(httpResponse.statusCode)") }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else { throw OpenAIError.invalidResponse }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
