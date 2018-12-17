//
//  TTS.swift (Text to Speech)
//  VoiceOnly
//
//  Created by Wangchou Lu on H30/04/16.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//

import Foundation
#if os(iOS)
import AVFoundation
import Promises

enum TTSError: Error {
    case TTSStop
}

class TTS: NSObject, AVSpeechSynthesizerDelegate {
    var synthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()
    var promise = Promise<Void>.pending()
    var targetLanguage: String {
        switch gameLang {
        case .jp:
            return "ja-JP"
        default:
            return "en-US"

        }
    }

    func say(
        _ text: String,
        voiceId: String,
        rate: Float = AVSpeechUtteranceDefaultSpeechRate // 0.5, range 0 ~ 1.0
        ) -> Promise<Void> {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        }
        synthesizer.delegate = self
        let utterance = AVSpeechUtterance(string: getFixedKanaForTTS(text))
        if let voice = AVSpeechSynthesisVoice(identifier: voiceId) {
            utterance.voice = voice
        } else {
            if targetLanguage == AVSpeechSynthesisVoice.currentLanguageCode() {
                // Do nothing, if not set utterance.voice
                // Siri will say it
            } else {
                utterance.voice = AVSpeechSynthesisVoice(language: targetLanguage)
            }
        }

        utterance.rate = rate
        postEvent(.sayStarted, string: text)
        synthesizer.speak(utterance)
        promise = Promise<Void>.pending()

        return promise
    }

    func stop() {
        synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
        promise.fulfill(())
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
        ) {
        postEvent(.speakEnded)
        promise.fulfill(())
    }

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance) {
        print(Date().timeIntervalSince1970, utterance.speechString.substring(with: characterRange)?.s)
        postEvent(.willSpeakRange, range: characterRange)
    }
}
#endif
