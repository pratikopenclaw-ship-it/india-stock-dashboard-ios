//
//  AIChatView.swift
//  ISDStockDashboard
//

import SwiftUI

struct AIChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    messageList
                    inputBar
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var messageList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(messages) { msg in
                    MessageBubble(message: msg)
                }
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(.isdAccent)
                        Spacer()
                    }
                    .padding()
                }
            }
            .padding()
        }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask about stocks, markets...", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .padding(10)
                .background(Color.isdCard)
                .foregroundColor(.isdTextPrimary)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
                .focused($isInputFocused)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(inputText.isEmpty ? .isdTextMuted : .isdAccent)
            }
            .disabled(inputText.isEmpty || isLoading)
        }
        .padding()
        .background(Color.isdCard)
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.isdBorder), alignment: .top)
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let userMsg = ChatMessage(id: UUID(), role: "user", content: inputText, timestamp: Date())
        messages.append(userMsg)
        let query = inputText
        inputText = ""
        isLoading = true

        Task {
            // Simulate AI response - in production this would call a backend endpoint
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                let aiMsg = ChatMessage(
                    id: UUID(),
                    role: "assistant",
                    content: "I'm analyzing \(query). For detailed AI insights, please check the Agent Debate section for any stock-specific analysis.",
                    timestamp: Date()
                )
                messages.append(aiMsg)
                isLoading = false
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id: UUID
    let role: String
    let content: String
    let timestamp: Date
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == "user" { Spacer() }
            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.subheadline)
                    .foregroundColor(.isdTextPrimary)
                    .padding(12)
                    .background(message.role == "user" ? Color.isdAccent : Color.isdCard)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(message.role == "user" ? Color.clear : Color.isdBorder, lineWidth: 1))
                    .cornerRadius(12)
            }
            if message.role == "assistant" { Spacer() }
        }
    }
}

#Preview {
    AIChatView()
}
