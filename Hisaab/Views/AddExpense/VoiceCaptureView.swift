import SwiftUI
import Speech
import AVFoundation
import SwiftData

// MARK: - Speech Recognition Manager

@Observable
final class SpeechRecognitionManager: @unchecked Sendable {
    var transcript = ""
    var isListening = false
    var authorizationError: String?

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // Indian English improves recognition of local names, rupee amounts, and UPI apps
    private let speechRecognizer: SFSpeechRecognizer? =
        SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
        ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        ?? SFSpeechRecognizer()

    @discardableResult
    func requestAndStart() async -> Bool {
        authorizationError = nil
        let status = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard status == .authorized else {
            DispatchQueue.main.async {
                self.authorizationError = "Allow speech recognition in Settings → Privacy & Security → Speech Recognition."
            }
            return false
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            DispatchQueue.main.async { self.authorizationError = "Microphone unavailable." }
            return false
        }
        DispatchQueue.main.async { self.startRecording() }
        return true
    }

    func stopListening() {
        DispatchQueue.main.async { self.stopRecording() }
    }

    private func startRecording() {
        transcript = ""
        isListening = true

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else { isListening = false; return }
        request.shouldReportPartialResults = true
        // Honour the spec's privacy requirement when the device supports it
        request.requiresOnDeviceRecognition = speechRecognizer?.supportsOnDeviceRecognition == true

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let result { self.transcript = result.bestTranscription.formattedString }
                if error != nil || result?.isFinal == true { self.stopRecording() }
            }
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        try? audioEngine.start()
    }

    private func stopRecording() {
        guard isListening else { return }
        isListening = false
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Voice Capture View

private enum CapturePhase { case listening, confirming }

struct VoiceCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Query(sort: \ExpenseCategory.sortOrder) private var categories: [ExpenseCategory]

    @State private var manager = SpeechRecognitionManager()
    @State private var phase: CapturePhase = .listening

    // Confirmation fields — set from VoiceParser output, editable by user
    @State private var amountText = ""
    @State private var confirmedCategory = ""
    @State private var confirmedNote = ""

    // Controls the pulse ring animation
    @State private var pulsing = false

    var body: some View {
        VStack(spacing: 0) {
            dragHandle

            switch phase {
            case .listening:  listeningView
            case .confirming: confirmationView
            }
        }
        .background(Color(.systemGroupedBackground))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .task { await startListening() }
        .onChange(of: manager.isListening) { _, nowListening in
            // Natural end of recognition (timeout or final result) triggers confirmation
            guard !nowListening, phase == .listening else { return }
            parseAndConfirm()
        }
        .onDisappear { manager.stopListening() }
    }

    // MARK: - Drag handle

    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color(.tertiaryLabel))
            .frame(width: 40, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }

    // MARK: - Listening phase

    private var listeningView: some View {
        VStack(spacing: 32) {
            Spacer()

            // Live transcript / status text
            Group {
                if let error = manager.authorizationError {
                    VStack(spacing: 12) {
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                    }
                } else if manager.transcript.isEmpty {
                    Text("Listening...")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                } else {
                    Text(manager.transcript)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 80)
            .padding(.horizontal, 28)
            .animation(.easeInOut(duration: 0.15), value: manager.transcript)

            // Mic button with breathing pulse rings
            ZStack {
                if manager.isListening {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 108, height: 108)
                        .scaleEffect(pulsing ? 1.3 : 1.0)
                        .opacity(pulsing ? 0.0 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulsing)

                    Circle()
                        .fill(Color.accentColor.opacity(0.07))
                        .frame(width: 138, height: 138)
                        .scaleEffect(pulsing ? 1.25 : 1.0)
                        .opacity(pulsing ? 0.0 : 1.0)
                        .animation(.easeInOut(duration: 1.0).delay(0.15).repeatForever(autoreverses: true), value: pulsing)
                        .onAppear { pulsing = true }
                        .onDisappear { pulsing = false }
                }

                Button { manager.stopListening() } label: {
                    Image(systemName: manager.isListening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(manager.isListening ? Color.red : Color.accentColor)
                        .clipShape(Circle())
                        .shadow(
                            color: (manager.isListening ? Color.red : Color.accentColor).opacity(0.4),
                            radius: 14, y: 4
                        )
                }
                .buttonStyle(PressScaleButtonStyle())
            }
            .frame(height: 150)

            Text(manager.isListening ? "Tap to stop" : " ")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .animation(.easeInOut(duration: 0.2), value: manager.isListening)

            Spacer()
        }
        .padding(.bottom, 24)
    }

    // MARK: - Confirmation phase

    private var confirmationView: some View {
        ScrollView {
            VStack(spacing: 16) {
                amountCard
                categoryCard
                noteCard

                Button(action: save) {
                    Text("Save Expense")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSave ? Color.accentColor : Color(.systemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressScaleButtonStyle())
                .disabled(!canSave)

                Button { Task { await startListening() } } label: {
                    Text("Try again")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(20)
            .padding(.bottom, 16)
        }
    }

    private var amountCard: some View {
        VStack(spacing: 6) {
            Text("Amount")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("₹")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                TextField("0", text: $amountText)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories) { cat in
                        chipButton(cat)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            TextField("Optional note", text: $confirmedNote)
                .font(.body)
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func chipButton(_ cat: ExpenseCategory) -> some View {
        let selected = confirmedCategory == cat.name
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                confirmedCategory = cat.name
            }
        } label: {
            HStack(spacing: 6) {
                Text(cat.emoji)
                Text(cat.name)
                    .font(.subheadline)
                    .fontWeight(selected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? Color.accentColor : Color(.tertiarySystemBackground))
            .foregroundStyle(selected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    // MARK: - Logic

    private var canSave: Bool {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: "")) else { return false }
        return amount > 0 && !confirmedCategory.isEmpty
    }

    private func startListening() async {
        phase = .listening
        amountText = ""
        confirmedNote = ""
        await manager.requestAndStart()
    }

    private func parseAndConfirm() {
        guard phase == .listening else { return }
        let parsed = VoiceParser.parse(manager.transcript, availableCategories: categories.map(\.name))
        if let amount = parsed.amount {
            amountText = amount.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(amount)) : String(amount)
        }
        confirmedCategory = parsed.category ?? categories.first?.name ?? ""
        confirmedNote = parsed.note ?? ""
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            phase = .confirming
        }
    }

    private func save() {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: "")), amount > 0 else { return }
        modelContext.insert(Expense(
            amount: amount,
            category: confirmedCategory,
            note: confirmedNote.isEmpty ? nil : confirmedNote,
            source: .voice
        ))
        dismiss()
    }
}
