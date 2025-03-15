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
    var result = ""
    var usingStream = true
    private var cancellable: Set<AnyCancellable> = []
    
    init() {
        let path = Bundle.main.path(forResource: "ds", ofType: "gguf") ?? ""
        swiftLlama = (try? SwiftLlama(modelPath: path))!
    }
    
    func run(for userMessage: String)-> String {
        result = ""
        let prompt = Prompt(type: .llama3,
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
                            userMessage: userMessage)
        Task {
            switch usingStream {
            case true:
                for try await value in await swiftLlama.start(for: prompt) {
                    print(result)
                    result += value
                }
            case false:
                await swiftLlama.start(for: prompt)
                    .sink { _ in

                    } receiveValue: {[weak self] value in
                        self?.result += value
                    }.store(in: &cancellable)
            }
        }
        return result
    }
    
}
