//
//  LLMFunctions.swift
//  Zedit-UIKit
//
//  Created by VR on 05/02/25.
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
        let path = Bundle.main.path(forResource: "tinyllama", ofType: "gguf") ?? ""
        swiftLlama = (try? SwiftLlama(modelPath: path))!
    }
    
    func run(for userMessage: String) {
        result = ""
        let prompt = Prompt(type: .llama3,
                            systemPrompt: "You are a helpful coding AI assistant.",
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
    }
}



