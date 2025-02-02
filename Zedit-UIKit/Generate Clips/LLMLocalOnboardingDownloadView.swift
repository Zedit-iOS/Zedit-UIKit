//
//  LLMLocalOnboardingDownloadView.swift
//  Zedit-UIKit
//
//  Created by Avinash on 02/02/25.
//

import SwiftUI
import SpeziLLMLocalDownload

struct LLMLocalOnboardingDownloadView: View {
    @State private var isDownloading: Bool = false
    var onDownloadComplete: () -> Void // Closure to call when download completes


    var body: some View {
        LLMLocalDownloadView(
                    downloadDescription: "The Llama2 7B model will be downloaded",
                    llmDownloadUrl: LLMLocalDownloadManager.LLMUrlDefaults.llama2ChatModelUrl, // Download the Llama2 7B model
                    llmStorageUrl: .cachesDirectory.appending(path: "llm.gguf"),
                    action: {
                                    print("success") // Print success when the download completes
                        onDownloadComplete()
                                }
                )
        .onAppear {
            // You can add additional logic here if needed when the view appears
        }
        .padding()
    }
}

struct LLMLocalOnboardingDownloadView_Previews: PreviewProvider {
    static var previews: some View {
        LLMLocalOnboardingDownloadView {
            // Mock closure for previews
        }
    }
}
