//
//  TTSManager.swift
//  Kartrider
//
//  Created by 박난 on 6/2/25.
//
import Foundation
import AVFoundation

final class TTSManager: NSObject, @unchecked Sendable, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private var currentContinuation: CheckedContinuation<Void, Never>?

    @MainActor @Published private(set) var state: TTSState = .inactive
    var didSpeakingStateChanged: ((Bool) -> Void)?

    private var lastUtteranceText: String?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // TODO: 전체적인 개선이 필요해 보임
    func speakSequentially(_ text: String) async {
        Log.info("speakSequentially 호출")

        while await self.state == .paused {
            Log.debug("[speakSequentially] 일시정지 상태, 대기 중...")
            try? await Task.sleep(for: .milliseconds(100))
        }

        let currentState = await self.state
        guard currentState == .inactive else {
            Log.warning("현재 state=\(currentState), speakSequentially는 무시됨")
            return
        }

        await MainActor.run {
            self.state = .playing
        }

        lastUtteranceText = text

        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume()
                return
            }

            self.currentContinuation = continuation
            self.speak(text)
        }
    }

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
        synthesizer.speak(utterance)
    }

    func pause() {
        Log.debug("pause 호출")

        guard synthesizer.isSpeaking else {
            Log.warning("pause 호출 시 재생 중이 아님")
            return
        }

        _ = synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {
        Log.debug("resume 호출")

        guard synthesizer.isPaused else {
            Log.warning("resume 호출 시 일시정지 상태가 아님")
            return
        }

        let result = synthesizer.continueSpeaking()
        Log.debug("continueSpeaking 결과: \(result)")
    }

    func stop() {
        Log.debug("stop 호출")
        synthesizer.stopSpeaking(at: .immediate)

        currentContinuation?.resume()
        currentContinuation = nil

        Task { @MainActor in
            self.state = .inactive
            self.didSpeakingStateChanged?(false)
        }
    }

    func toggleSpeaking() {
        Log.info("toggleSpeaking 호출")
        Task { @MainActor in
            switch self.state {
            case .playing:
                self.pause()
            case .paused:
                self.resume()
            case .inactive:
                // idle인데 마지막 텍스트가 있다면 다시 시작
                if let last = self.lastUtteranceText {
                    Log.info("toggleSpeaking - idle 상태에서 마지막 텍스트 재생 시작")
                    Task {
                        await self.speakSequentially(last)
                    }
                } else {
                    Log.warning("toggleSpeaking - idle 상태이지만 마지막 텍스트 없음")
                }
            case .finished:
                Log.info("toggleSpeaking - finished 상태")
            }
        }
    }
}

extension TTSManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.state = .playing
            self.didSpeakingStateChanged?(true)
            Log.debug("didStart")
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.state = .paused
            self.didSpeakingStateChanged?(false)
            Log.debug("didPause")
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.state = .playing
            self.didSpeakingStateChanged?(true)
            Log.debug("didContinue")
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.state = .inactive
            self.didSpeakingStateChanged?(false)
            Log.debug("didFinish")
        }

        currentContinuation?.resume()
        currentContinuation = nil
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.state = .inactive
            self.didSpeakingStateChanged?(false)
            Log.debug("didCancel")
        }

        currentContinuation?.resume()
        currentContinuation = nil
    }
}
