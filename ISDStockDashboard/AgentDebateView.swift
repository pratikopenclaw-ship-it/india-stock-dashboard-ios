//
//  AgentDebateView.swift
//  ISDStockDashboard
//

import SwiftUI

struct AgentDebateView: View {
    @State private var history: [AgentAnalysisRecord] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var searchSymbol = ""
    @State private var showingAnalyzeSheet = false
    @State private var selectedTab = 0
    private let tabs = ["History", "Risk", "Memory"]

    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    tabPicker
                    List {
                        if isLoading {
                            Section {
                                ProgressView("Loading agent history...")
                                    .tint(.isdTextSecondary)
                                    .padding()
                            }
                        } else if let error = errorMessage {
                            Section {
                                ContentUnavailableView {
                                    Label("Error", systemImage: "exclamationmark.triangle")
                                } description: {
                                    Text(error)
                                } actions: {
                                    Button("Retry") {
                                        Task { await loadData() }
                                    }
                                }
                            }
                        } else if history.isEmpty {
                            Section {
                                ContentUnavailableView {
                                    Label("No Analysis", systemImage: "brain.head.profile")
                                } description: {
                                    Text("Run an AI agent analysis on a stock to see debate results")
                                } actions: {
                                    Button("Analyze a Stock") {
                                        showingAnalyzeSheet = true
                                    }
                                }
                            }
                        } else {
                            tabContent
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Agent Debate")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAnalyzeSheet = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.isdAccent)
                    }
                }
            }
            .sheet(isPresented: $showingAnalyzeSheet) {
                AnalyzeStockView { ticker in
                    Task { await loadData() }
                }
            }
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
        }
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button {
                    selectedTab = index
                } label: {
                    Text(tabs[index])
                        .font(.system(size: 13, weight: selectedTab == index ? .semibold : .medium))
                        .foregroundColor(selectedTab == index ? .isdAccent : .isdTextMuted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedTab == index ? Color.isdAccent.opacity(0.10) : Color.clear)
                }
            }
        }
        .background(Color.isdCard)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
        .cornerRadius(6)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0:
            ForEach(history) { record in
                AgentRecordRow(record: record)
            }
        case 1:
            ForEach(history) { record in
                RiskRecordRow(record: record)
            }
        case 2:
            ForEach(history) { record in
                MemoryRecordRow(record: record)
            }
        default:
            EmptyView()
        }
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            history = try await api.fetchAgentHistory()
        } catch APIError.unauthorized {
            errorMessage = "Please sign in to view agent debates"
        } catch {
            errorMessage = "Failed to load agent history"
        }
        isLoading = false
    }
}

struct AgentRecordRow: View {
    let record: AgentAnalysisRecord
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(record.ticker)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.isdTextPrimary)

                        Text(record.signal.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundColor(signalColor)
                            .background(signalColor.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(signalColor.opacity(0.30), lineWidth: 1))
                            .cornerRadius(4)

                        Spacer()
                    }

                    Text(record.trade_date)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.isdTextSecondary)
                        .font(.system(size: 14, weight: .semibold))
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    if let decision = record.final_decision {
                        Text(decision)
                            .font(.subheadline)
                            .foregroundColor(.isdTextPrimary)
                            .lineLimit(8)
                    }

                    if let debate = record.debate {
                        VStack(alignment: .leading, spacing: 6) {
                            if let bull = debate.bull_history {
                                Label {
                                    Text(bull)
                                        .font(.caption)
                                        .foregroundColor(.isdGreen)
                                        .lineLimit(4)
                                } icon: {
                                    Image(systemName: "arrow.up")
                                        .foregroundColor(.isdGreen)
                                }
                            }
                            if let bear = debate.bear_history {
                                Label {
                                    Text(bear)
                                        .font(.caption)
                                        .foregroundColor(.isdRed)
                                        .lineLimit(4)
                                } icon: {
                                    Image(systemName: "arrow.down")
                                        .foregroundColor(.isdRed)
                                }
                            }
                        }
                    }

                    if let plan = record.investment_plan {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("INVESTMENT PLAN")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.isdTextMuted)
                                .tracking(0.3)
                            Text(plan)
                                .font(.caption)
                                .foregroundColor(.isdTextSecondary)
                                .lineLimit(5)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.isdCard)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
    }

    private var signalColor: Color {
        switch record.signal.lowercased() {
        case "buy", "overweight", "strong_buy": return .isdGreen
        case "sell", "underweight", "strong_sell": return .isdRed
        default: return .isdAccent
        }
    }
}

struct RiskRecordRow: View {
    let record: AgentAnalysisRecord
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(record.ticker)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.isdTextPrimary)
                        Text("RISK")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundColor(.isdRed)
                            .background(Color.isdRed.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.isdRed.opacity(0.30), lineWidth: 1))
                            .cornerRadius(4)
                        Spacer()
                    }
                    Text(record.trade_date)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.isdTextSecondary)
                        .font(.system(size: 14, weight: .semibold))
                }
            }

            if isExpanded, let risk = record.risk_debate {
                VStack(alignment: .leading, spacing: 10) {
                    if let aggressive = risk.aggressive {
                        riskView(label: "AGGRESSIVE", text: aggressive, color: .isdRed)
                    }
                    if let conservative = risk.conservative {
                        riskView(label: "CONSERVATIVE", text: conservative, color: .isdGreen)
                    }
                    if let neutral = risk.neutral {
                        riskView(label: "NEUTRAL", text: neutral, color: .isdAccent)
                    }
                    if let decision = risk.judge_decision {
                        riskView(label: "JUDGE DECISION", text: decision, color: .isdGold)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.isdCard)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
    }

    private func riskView(label: String, text: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(color)
                .tracking(0.3)
            Text(text)
                .font(.caption)
                .foregroundColor(.isdTextSecondary)
                .lineLimit(5)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(color.opacity(0.10))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(0.30), lineWidth: 1))
        .cornerRadius(6)
    }
}

struct MemoryRecordRow: View {
    let record: AgentAnalysisRecord
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(record.ticker)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.isdTextPrimary)
                        Text("MEMORY")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .foregroundColor(.isdAccent)
                            .background(Color.isdAccent.opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.isdAccent.opacity(0.30), lineWidth: 1))
                            .cornerRadius(4)
                        Spacer()
                    }
                    Text(record.trade_date)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.isdTextMuted)
                }
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.isdTextSecondary)
                        .font(.system(size: 14, weight: .semibold))
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    if let trader = record.trader_proposal {
                        memoryView(label: "TRADER PROPOSAL", text: trader)
                    }
                    if let plan = record.investment_plan {
                        memoryView(label: "INVESTMENT PLAN", text: plan)
                    }
                    if let holdings = record.holdings_aware_decision {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "briefcase.fill")
                                    .foregroundColor(.isdGold)
                                    .font(.caption)
                                Text("HOLDINGS CONTEXT")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(.isdGold)
                                    .tracking(0.3)
                            }
                            Text(holdings)
                                .font(.caption)
                                .foregroundColor(.isdAccent)
                                .lineLimit(5)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color.isdGold.opacity(0.06))
                        .cornerRadius(4)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.isdCard)
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
    }

    private func memoryView(label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.isdTextMuted)
                .tracking(0.3)
            Text(text)
                .font(.caption)
                .foregroundColor(.isdTextSecondary)
                .lineLimit(5)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.isdCard.opacity(0.5))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder.opacity(0.5), lineWidth: 1))
    }
}

struct AnalyzeStockView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var symbol = ""
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var jobId: String?
    @State private var jobStatus: String?
    @State private var jobResult: AgentJobResponse?

    let onComplete: (String) -> Void
    private let api = APIClient.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.isdBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    if let result = jobResult, result.status == "done" {
                        AgentResultCard(result: result)
                    } else if isAnalyzing {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.isdAccent)
                                .scaleEffect(1.5)
                            Text("AI agents analyzing \(symbol.uppercased())...")
                                .font(.subheadline)
                                .foregroundColor(.isdTextSecondary)
                            if let status = jobStatus {
                                Text(status)
                                    .font(.caption)
                                    .foregroundColor(.isdTextMuted)
                            }
                        }
                        .padding()
                    } else {
                        VStack(spacing: 16) {
                            TextField("Enter stock symbol (e.g. RELIANCE)", text: $symbol)
                                .textInputAutocapitalization(.characters)
                                .padding()
                                .background(Color.isdCard)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.isdBorder, lineWidth: 1))
                                .cornerRadius(6)
                                .foregroundColor(.isdTextPrimary)

                            Button {
                                Task { await startAnalysis() }
                            } label: {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                    Text("Start Agent Analysis")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.isdAccent)
                                .foregroundStyle(Color.isdTextPrimary)
                                .cornerRadius(6)
                            }
                            .disabled(symbol.isEmpty || isAnalyzing)

                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.isdRed)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("New Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func startAnalysis() async {
        isAnalyzing = true
        errorMessage = nil
        do {
            let response = try await api.startAgentAnalysis(ticker: symbol)
            jobId = response.job_id
            jobStatus = "running"

            // Poll for result
            var attempts = 0
            while attempts < 60 {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                let status = try await api.getAgentJobStatus(jobId: response.job_id)
                jobStatus = status.status
                if status.status == "done" {
                    jobResult = status
                    onComplete(symbol)
                    break
                } else if status.status == "error" {
                    errorMessage = status.detail ?? "Analysis failed"
                    break
                }
                attempts += 1
            }
            if attempts >= 60 {
                errorMessage = "Analysis timed out. Check history later."
            }
        } catch {
            errorMessage = "Failed to start analysis"
        }
        isAnalyzing = false
    }
}

struct AgentResultCard: View {
    let result: AgentJobResponse

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Text(result.ticker?.uppercased() ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.isdTextPrimary)

                    if let signal = result.signal {
                        Text(signal.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .foregroundColor(signalColor(signal))
                            .background(signalColor(signal).opacity(0.10))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(signalColor(signal).opacity(0.30), lineWidth: 1))
                            .cornerRadius(4)
                    }
                }

                if let decision = result.final_decision {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FINAL DECISION")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.isdTextMuted)
                            .tracking(0.3)
                        Text(decision)
                            .font(.subheadline)
                            .foregroundColor(.isdTextPrimary)
                    }
                }

                if let debate = result.debate {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("AGENT DEBATE")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.isdTextMuted)
                            .tracking(0.3)

                        if let bull = debate.bull_history {
                            Label {
                                Text(bull)
                                    .font(.caption)
                                    .foregroundColor(.isdGreen)
                            } icon: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(.isdGreen)
                            }
                        }
                        if let bear = debate.bear_history {
                            Label {
                                Text(bear)
                                    .font(.caption)
                                    .foregroundColor(.isdRed)
                            } icon: {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(.isdRed)
                            }
                        }
                    }
                }

                if let plan = result.investment_plan {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("INVESTMENT PLAN")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.isdTextMuted)
                            .tracking(0.3)
                        Text(plan)
                            .font(.caption)
                            .foregroundColor(.isdTextSecondary)
                    }
                }

                if let holdingDecision = result.holdings_aware_decision {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PORTFOLIO MANAGER")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.isdTextMuted)
                            .tracking(0.3)
                        Text(holdingDecision)
                            .font(.caption)
                            .foregroundColor(.isdAccent)
                    }
                }
            }
            .padding()
        }
    }

    private func signalColor(_ signal: String) -> Color {
        switch signal.lowercased() {
        case "buy", "overweight", "strong_buy": return .isdGreen
        case "sell", "underweight", "strong_sell": return .isdRed
        default: return .isdAccent
        }
    }
}

#Preview {
    AgentDebateView()
}
