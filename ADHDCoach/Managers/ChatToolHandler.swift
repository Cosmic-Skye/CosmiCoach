import Foundation

/**
 * ChatToolHandler manages tool definitions and processing for Claude API integration.
 *
 * This class is responsible for:
 * - Providing tool definitions that Claude can use
 * - Processing memory updates from Claude's responses
 * - Providing helper methods for tool processing
 */
class ChatToolHandler {
    /// Callback for processing tool use requests from Claude
    /// Parameters:
    /// - toolName: The name of the tool to use
    /// - toolId: The unique ID of the tool use request
    /// - toolInput: The input parameters for the tool
    /// - messageId: The ID of the message associated with this tool use
    /// - chatManager: Reference to the ChatManager for status updates
    /// Returns: The result of the tool use as a string
    var processToolUseCallback: ((String, String, [String: Any], UUID?, ChatManager) async -> String)?
    
    /**
     * Returns the tool definitions that Claude can use.
     *
     * These definitions include calendar, reminder, and memory tools
     * with their input schemas and descriptions.
     *
     * @return An array of tool definitions in the format expected by Claude API
     */
    func getToolDefinitions() -> [[String: Any]] {
        return [
            // Calendar Tools - Single item operations
            [
                "name": "add_calendar_event",
                "description": "⚠️ ONLY FOR SINGLE EVENTS ⚠️ Use ONLY when adding exactly ONE calendar event. If adding multiple events (2+), you MUST use add_calendar_events_batch instead with an array of events.",
                "input_schema": CalendarAddCommand.schema
            ],
            [
                "name": "modify_calendar_event",
                "description": "⚠️ ONLY FOR SINGLE EVENTS ⚠️ Use ONLY when modifying exactly ONE calendar event. If modifying multiple events (2+), you MUST use modify_calendar_events_batch instead with an array of events.",
                "input_schema": CalendarModifyCommand.schema
            ],
            [
                "name": "delete_calendar_event",
                "description": "Delete one or more calendar events from the user's calendar. This tool handles both single and multiple deletions. You MUST provide either the 'id' parameter OR the 'ids' parameter, but not both.",
                "input_schema": [
                    "type": "object",
                    "properties": [
                        "id": ["type": "string", "description": "The ID of a single calendar event to delete. Use only when deleting exactly one event."],
                        "ids": ["type": "array", "description": "Array of calendar event IDs to delete. Use this when deleting one or more events.", "items": ["type": "string"]]
                    ]
                ]
            ],
            
            // Calendar Tools - Batch operations
            [
                "name": "add_calendar_events_batch",
                "description": "⚠️ REQUIRED FOR MULTIPLE EVENTS ⚠️ You MUST use this tool whenever adding 2+ calendar events at once. NEVER use add_calendar_event multiple times - always use this batch function with an array of events in the 'events' field. Format: {'events': [{'title': 'event1', 'start': 'date1', 'end': 'date2'}, {'title': 'event2', 'start': 'date3', 'end': 'date4'}]}",
                "input_schema": CalendarAddBatchCommand.schema
            ],
            [
                "name": "modify_calendar_events_batch",
                "description": "⚠️ REQUIRED FOR MULTIPLE EVENTS ⚠️ You MUST use this tool whenever modifying 2+ calendar events at once. NEVER use modify_calendar_event multiple times - always use this batch function with an array of events in the 'events' field. Format: {'events': [{'id': 'id1', 'title': 'title1'}, {'id': 'id2', 'title': 'title2'}]}",
                "input_schema": CalendarModifyBatchCommand.schema
            ],
            
            // Reminder Tools - Single item operations
            [
                "name": "add_reminder",
                "description": "⚠️ ONLY FOR SINGLE REMINDERS ⚠️ Use ONLY when adding exactly ONE reminder. If adding multiple reminders (2+), you MUST use add_reminders_batch instead with an array of reminders.",
                "input_schema": ReminderAddCommand.schema
            ],
            [
                "name": "modify_reminder",
                "description": "⚠️ ONLY FOR SINGLE REMINDERS ⚠️ Use ONLY when modifying exactly ONE reminder. If modifying multiple reminders (2+), you MUST use modify_reminders_batch instead with an array of reminders.",
                "input_schema": ReminderModifyCommand.schema
            ],
            [
                "name": "delete_reminder",
                "description": "Delete one or more reminders from the user's reminders list. This tool handles both single and multiple deletions. You MUST provide either the 'id' parameter OR the 'ids' parameter, but not both.",
                "input_schema": [
                    "type": "object",
                    "properties": [
                        "id": ["type": "string", "description": "The ID of a single reminder to delete. Use only when deleting exactly one reminder."],
                        "ids": ["type": "array", "description": "Array of reminder IDs to delete. Use this when deleting one or more reminders.", "items": ["type": "string"]]
                    ]
                ]
            ],
            
            // Reminder Tools - Batch operations
            [
                "name": "add_reminders_batch",
                "description": "⚠️ REQUIRED FOR MULTIPLE REMINDERS ⚠️ You MUST use this tool whenever adding 2+ reminders at once. NEVER use add_reminder multiple times - always use this batch function with an array of reminders in the 'reminders' field. Format: {'reminders': [{'title': 'title1', 'due': 'date1'}, {'title': 'title2', 'due': 'date2'}]}",
                "input_schema": ReminderAddBatchCommand.schema
            ],
            [
                "name": "modify_reminders_batch",
                "description": "⚠️ REQUIRED FOR MULTIPLE REMINDERS ⚠️ You MUST use this tool whenever modifying 2+ reminders at once. NEVER use modify_reminder multiple times - always use this batch function with an array of reminders in the 'reminders' field. Format: {'reminders': [{'id': 'id1', 'title': 'title1'}, {'id': 'id2', 'title': 'title2'}]}",
                "input_schema": ReminderModifyBatchCommand.schema
            ],
            
            // Memory Tools - Single item operations
            [
                "name": "add_memory",
                "description": "Add a new memory to the user's memory database. You MUST use this tool to store important information about the user that should persist between conversations.",
                "input_schema": MemoryAddCommand.schema
            ],
            [
                "name": "update_memory",
                "description": "Update an existing memory in the user's memory database. Use this tool when you need to modify information that already exists without deleting it.",
                "input_schema": [
                    "type": "object",
                    "properties": [
                        "id": ["type": "string", "description": "The ID of the memory to update, or the exact current content if you don't have the ID"],
                        "old_content": ["type": "string", "description": "The exact current content of the memory to update (alternative to providing ID)"], 
                        "content": ["type": "string", "description": "The new content for the memory"],
                        "category": ["type": "string", "description": "Optional new category for the memory (Personal Information, Preferences, Behavior Patterns, Daily Basics, Medications, Goals, Miscellaneous Notes)"],
                        "importance": ["type": "integer", "description": "Optional new importance level (1-5, with 5 being most important)"]
                    ],
                    "required": ["content"]
                ]
            ],
            [
                "name": "remove_memory",
                "description": "Remove a memory from the user's memory database. Use this tool when information becomes outdated or is no longer relevant.",
                "input_schema": MemoryRemoveCommand.schema
            ],
            
            // Memory Tools - Batch operations
            [
                "name": "add_memories_batch",
                "description": "Add multiple memories to the user's memory database at once. Use this tool when you need to store multiple pieces of important information in a single operation.",
                "input_schema": MemoryAddBatchCommand.schema
            ],
            [
                "name": "update_memories_batch",
                "description": "Update multiple existing memories in the user's memory database at once. Use this tool when you need to modify several pieces of information in a single operation.",
                "input_schema": [
                    "type": "object",
                    "properties": [
                        "memories": [
                            "type": "array",
                            "description": "Array of memories to update",
                            "items": [
                                "type": "object",
                                "properties": [
                                    "id": ["type": "string", "description": "The ID of the memory to update, or the exact current content if you don't have the ID"],
                                    "old_content": ["type": "string", "description": "The exact current content of the memory to update (alternative to providing ID)"],
                                    "content": ["type": "string", "description": "The new content for the memory"],
                                    "category": ["type": "string", "description": "Optional new category for the memory (Personal Information, Preferences, Behavior Patterns, Daily Basics, Medications, Goals, Miscellaneous Notes)"],
                                    "importance": ["type": "integer", "description": "Optional new importance level (1-5, with 5 being most important)"]
                                ],
                                "required": ["content"]
                            ]
                        ]
                    ],
                    "required": ["memories"]
                ]
            ],
            [
                "name": "remove_memories_batch",
                "description": "Remove multiple memories from the user's memory database at once. Use this tool when multiple pieces of information become outdated or are no longer relevant.",
                "input_schema": MemoryRemoveBatchCommand.schema
            ]
        ]
    }
    
    /**
     * Processes memory updates from Claude's response.
     *
     * This method supports both legacy bracket-based memory updates and
     * the newer structured memory instructions.
     *
     * @param response The text response from Claude
     * @param memoryManager The memory manager to use for updates
     * @param chatManager Optional ChatManager for context refreshing
     * @return Boolean indicating if memory was updated
     */
    func processMemoryUpdates(response: String, memoryManager: MemoryManager, chatManager: ChatManager? = nil) async -> Bool {
        // Support both old and new memory update formats for backward compatibility
        var memoryUpdated = false
        
        // 1. Check for old format memory updates
        let memoryUpdatePattern = "\\[MEMORY_UPDATE\\]([\\s\\S]*?)\\[\\/MEMORY_UPDATE\\]"
        if let regex = try? NSRegularExpression(pattern: memoryUpdatePattern, options: []) {
            let matches = regex.matches(in: response, range: NSRange(response.startIndex..., in: response))
            
            for match in matches {
                if let updateRange = Range(match.range(at: 1), in: response) {
                    let diffContent = String(response[updateRange])
                    print("Found legacy memory update instruction: \(diffContent.count) characters")
                    
                    // Apply the diff to the memory file
                    let success = await memoryManager.applyDiff(diff: diffContent.trimmingCharacters(in: .whitespacesAndNewlines))
                    
                    if success {
                        print("Successfully applied legacy memory update")
                        memoryUpdated = true
                    } else {
                        print("Failed to apply legacy memory update")
                    }
                }
            }
        }
        
        // 2. Check for new structured memory instructions
        // Process the new structured memory format
        // This uses the new method in MemoryManager
        let success = await memoryManager.processMemoryInstructions(instructions: response)
        
        if success {
            print("Successfully processed structured memory instructions")
            memoryUpdated = true
        }
        
        // 3. Refresh context if memory was updated and chatManager is provided
        if memoryUpdated && chatManager != nil {
            print("Memory was updated, refreshing context data")
            await chatManager?.refreshContextData()
        }
        
        return memoryUpdated
    }
    
    /**
     * Parses a date string into a Date object.
     *
     * @param dateString The date string in the format "MMM d, yyyy 'at' h:mm a"
     * @return A Date object if parsing was successful, nil otherwise
     */
    func parseDate(_ dateString: String) -> Date? {
        return DateFormatter.claudeDateParser.date(from: dateString)
    }
    
    /**
     * Creates fallback tool input when JSON parsing fails.
     *
     * This provides sensible defaults for different tool types to ensure
     * tool processing can continue even when input parsing fails.
     *
     * @param toolName The name of the tool to create fallback input for
     * @return A dictionary containing fallback input parameters
     */
    func createFallbackToolInput(toolName: String?) -> [String: Any] {
        let now = Date()
        
        switch toolName {
        case "add_calendar_event":
            let oneHourLater = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
            return [
                "title": "Test Calendar Event",
                "start": DateFormatter.claudeDateParser.string(from: now),
                "end": DateFormatter.claudeDateParser.string(from: oneHourLater),
                "notes": "Created by Claude when JSON parsing failed"
            ]
        case "add_reminder":
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
            return [
                "title": "Test Reminder",
                "due": DateFormatter.claudeDateParser.string(from: tomorrow),
                "notes": "Created by Claude when JSON parsing failed"
            ]
        case "add_memory":
            return [
                "content": "User asked Claude to create a test memory",
                "category": "Miscellaneous Notes",
                "importance": 3
            ]
        default:
            // For other tools, provide a basic fallback
            return ["note": "Fallback tool input for \(toolName ?? "unknown tool")"]
        }
    }
}
