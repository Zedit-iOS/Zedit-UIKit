//
//  Llama.swift
//  Zedit-UIKit
//
//  Created by Avinash on 12/01/25.
//

import Foundation

class Llama {
    private var llamaContext: LlamaContext?

    // Singleton instance
    static let shared = Llama()

    private init() {}

    /// Copies the model from the app bundle to local storage if it doesn't already exist.
    private func copyModelToLocalStorage() -> URL? {
        let fileManager = FileManager.default
        guard let bundleURL = Bundle.main.url(forResource: "tinyllama-1.1b-1t-openorca.Q4_0", withExtension: "gguf", subdirectory: "models") else {
            print("Model file not found in bundle.")
            return nil
        }

        let destinationURL = getDocumentsDirectory().appendingPathComponent("tinyllama-1.1b-1t-openorca.Q4_0.gguf")

        if !fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.copyItem(at: bundleURL, to: destinationURL)
                print("Model successfully copied to local storage.")
            } catch {
                print("Error copying model to local storage: \(error)")
                return nil
            }
        } else {
            print("Model already exists in local storage.")
        }

        return destinationURL
    }

    /// Returns the app's documents directory URL.
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    /// Initializes the llama model.
    func initializeModel() -> Bool {
        guard let modelPath = copyModelToLocalStorage() else {
            print("Failed to retrieve model path.")
            return false
        }

        do {
            print("Initializing Llama model...")
            llamaContext = try LlamaContext.create_context(path: modelPath.path)
            print("Model successfully loaded.")
            return true
        } catch {
            print("Failed to initialize model: \(error)")
            return false
        }
    }

    /// Provides a success message if the model is loaded.
    func isModelLoaded() -> Bool {
        return llamaContext != nil
    }
}

