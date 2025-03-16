//
//  LLMFunctions.swift
//  Zedit-UIKit
//
//  Created by Avinash on 12/03/25.
//


import Foundation
import SwiftLlama
import Combine

@Observable
class LLM {
    let swiftLlama: SwiftLlama
    var usingStream = true
    
    init() {
        // Always load the model from the app bundle using "ds.gguf"
        let path = Bundle.main.path(forResource: "ds", ofType: "gguf") ?? ""
        swiftLlama = try! SwiftLlama(modelPath: path)
    }
    
    /// Runs the LLM asynchronously and returns the complete output string.
    func run(for userMessage: String) async throws -> String {
        let prompt = Prompt(
            type: .llama3,
            systemPrompt: """
            Given this video transcript and scene changes, identify the optimal clip segments. 
            The scene changes are provided as a list of timestamps, and the transcript is provided as a list of timestamp-text pairs. 
            Return a list of timestamps where the video can be clipped.

            RULES:
            1. Do not cut dialogues abruptly.
            2. Do not return the scene ranges as they are; analyze them properly.
            3. Return only a list of numbers representing seconds in the format [num1, num2, num3] without explanations.
            4. Your output must reflect the actual input data provided below, not just example values.

            VERY IMPORTANT: DIALOGUE SHOULD CUT ABRUPTLY!!

            Output:
            """,
            userMessage: userMessage
        )
        
        var output = ""
        if usingStream {
            // Accumulate each chunk until the stream is complete.
            for try await chunk in await swiftLlama.start(for: prompt) {
                output += chunk
                print(output)
            }
        } else {
            output = try await swiftLlama.start(for: prompt)
        }
        return output
    }
}

func getClipTimestamps(
    timestamps: [String],
    sceneRanges: [[Double]],
    videoURL: URL
) async throws -> [Double]? {
    let llm = LLM()
    let inputMessage = "the timestamps are: \(timestamps) and scene ranges are: \(sceneRanges)"
    
    let resultString = try await llm.run(for: inputMessage)
    print("LLM output: \(resultString)")
    
    // Remove any null characters and clean the string.
    var cleaned = resultString.replacingOccurrences(of: "\0", with: "")
    
    // Find the first occurrence of '['.
    guard let bracketIndex = cleaned.firstIndex(of: "[") else {
        print("No opening bracket found in output: \(cleaned)")
        return nil
    }
    
    // Extract everything from the first '[' onward.
    var bracketString = String(cleaned[bracketIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
    
    // If there's no closing bracket, append one.
    if !bracketString.hasSuffix("]") {
        bracketString.append("]")
    }
    
    // Verify the string now starts with '[' and ends with ']'.
    guard bracketString.first == "[" && bracketString.last == "]" else {
        print("Bracket extraction error: \(bracketString)")
        return nil
    }
    
    // Remove the brackets to get the inner content.
    let innerContent = bracketString.dropFirst().dropLast()
    
    // Split the content by commas.
    let stringNumbers = innerContent.split(separator: ",")
    if stringNumbers.isEmpty {
        print("No numbers found inside the brackets.")
        return nil
    }
    
    // Convert each substring to a Double and remove duplicates while preserving order.
    var seen = Set<Double>()
    var numbers: [Double] = []
    for substring in stringNumbers {
        let trimmed = substring.trimmingCharacters(in: .whitespaces)
        if let value = Double(trimmed) {
            if !seen.contains(value) {
                seen.insert(value)
                numbers.append(value)
            }
        } else {
            print("Conversion failed for value: \(trimmed)")
            return nil
        }
    }
    
    return numbers
}
