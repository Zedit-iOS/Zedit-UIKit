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
        let path = Bundle.main.path(forResource: "", ofType: "gguf") ?? ""
        swiftLlama = (try? SwiftLlama(modelPath: path))!
    }
    
    func run(for userMessage: String)-> String {
        result = ""
        let prompt = Prompt(type: .llama3,
                            systemPrompt: "You are proffesional video clipper, where you just provide the list of timestamps where the video can be clipped by analyzing the data provided. 2 data is provided, first is the list of timestamps of scene changes according to OpenCV and second is the transcript with the timestamps. Provide the final result in list of timestamps where the video can be clipped dont provide any other text than this example: [0, 0.320, 2.34, 3]]. Also don't hallucinate",
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
