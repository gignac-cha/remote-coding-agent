#!/usr/bin/env node

/**
 * @file json-stream-parser.js
 * @description Reads a stream of newline-delimited JSON objects from stdin,
 * parses them, and formats them into a human-readable log format.
 * This is designed to process the output of tools that produce structured JSON logs.
 */

const readline = require('readline');

const MAX_LINES = 30;
const MAX_LENGTH = 2000;

// --- Helper Functions ---

/**
 * Truncates content if it exceeds a maximum number of lines or a maximum length.
 * @param {string} content The content to truncate.
 * @returns {string} The (potentially) truncated content.
 */
function truncateContent(content) {
    if (!content) return '';

    const lines = content.split('\n');
    if (lines.length > MAX_LINES) {
        return lines.slice(0, MAX_LINES).join('\n') + `\n... (omitted ${lines.length - MAX_LINES} lines)`;
    }

    if (content.length > MAX_LENGTH) {
        return content.substring(0, MAX_LENGTH) + `... (omitted ${content.length - MAX_LENGTH} characters)`;
    }

    return content;
}

/**
 * Prints a divider line to the console to visually separate log sections.
 * @param {string} [character='-'] The character to use for the divider.
 * @param {number} [length=50] The length of the divider.
 */
function printDivider(character = '-', length = 50) {
  console.log(character.repeat(length));
}

/**
 * Formats and prints a log entry representing a tool call.
 * @param {object} log The parsed JSON log object.
 */
function formatToolCall(log) {
  try {
    const toolUse = log.message.content.find(c => c.type === 'tool_use');
    if (!toolUse) return;

    const toolName = toolUse.name;
    const input = toolUse.input;

    console.log(`
▶️  Tool Call: ${toolName}`);
    if (input.command) {
      console.log(`   Command: ${input.command}`);
    }
    if (input.description) {
        console.log(`   Description: ${input.description}`);
    }
    if (input.file_path) {
        console.log(`   File: ${input.file_path}`);
    }
    if (input.content) {
        const truncatedContent = truncateContent(input.content);
        console.log('   Content: \n' + truncatedContent.split('\n').map(l => `     > ${l}`).join('\n'));
    }

  } catch (e) {
    // Ignore if parsing fails, it might be a different or malformed message structure.
  }
}

/**
 * Formats and prints a log entry representing the result of a tool call.
 * @param {object} log The parsed JSON log object.
 */
function formatToolResult(log) {
  try {
    const toolResult = log.message.content.find(c => c.type === 'tool_result');
    if (!toolResult) return;

    console.log(`\n◀️  Tool Result:`);
    if (toolResult.is_error) {
        console.log('   Status: ❌ ERROR');
    } else {
        console.log('   Status: ✅ SUCCESS');
    }

    if (toolResult.content) {
        const content = toolResult.content.trim();
        const truncatedContent = truncateContent(content);
        console.log('   Output: \n' + truncatedContent.split('\n').map(l => `     | ${l}`).join('\n'));
    }

  } catch (e) {
    // Ignore if parsing fails.
  }
}

/**
 * Formats and prints a log entry representing a message from the AI assistant.
 * @param {object} log The parsed JSON log object.
 */
function formatAssistantMessage(log) {
    try {
        const textContent = log.message.content.find(c => c.type === 'text');
        if (!textContent || !textContent.text.trim()) return;

        printDivider('=', 50);
        console.log(`\n🤖 Assistant Message:`);
        console.log(`   ${textContent.text}`);
        printDivider('=', 50);

    } catch(e) {
        // Ignore.
    }
}

/**
 * Formats and prints the final result summary of the entire operation.
 * @param {object} log The parsed JSON log object.
 */
function formatResult(log) {
    try {
        if (log.type === 'result' && log.subtype === 'success') {
            printDivider('*', 50);
            console.log('\n🏁 Final Result:');
            console.log(`   ${log.result}`);
            console.log(`   Turns: ${log.num_turns}, Duration: ${log.duration_ms}ms, Cost: $${log.total_cost_usd.toFixed(6)}`);
            printDivider('*', 50);
        }
    } catch(e) {
        // Ignore.
    }
}


// --- Main execution ---

// Create a readline interface to read from standard input line by line.
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false // This ensures it works correctly with piped input.
});

// Process each line from the input stream.
rl.on('line', (line) => {
  try {
    const log = JSON.parse(line);

    // Route the parsed log to the appropriate formatting function based on its content.
    if (log.type === 'assistant' && log.message.content.some(c => c.type === 'tool_use')) {
      formatToolCall(log);
    } else if (log.type === 'user' && log.message.content.some(c => c.type === 'tool_result')) {
      formatToolResult(log);
    } else if (log.type === 'assistant' && log.message.content.some(c => c.type === 'text')) {
        formatAssistantMessage(log);
    } else if (log.type === 'result') {
        formatResult(log);
    }

  } catch (error) {
    // If a line is not valid JSON, it might be introductory text or an error message.
    // We choose to ignore it to prevent the parser from crashing.
    // For debugging, you could uncomment the lines below.
    // console.error('--- Non-JSON Line ---');
    // console.error(line);
  }
});

// Optional: Handle the close event of the input stream.
rl.on('close', () => {
    // console.log('\n--- Log parsing complete ---');
});

// Generated by Gemini