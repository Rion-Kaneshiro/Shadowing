//
//  SpeechRecognizer.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on H30/04/16.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//

import Foundation
import Promises
import Speech

private let context = GameContext.shared
private let engine = SpeechEngine.shared

enum SpeechRecognitionError: Error {
    case unauthorized
    case engineStopped
}

class SpeechRecognizer: NSObject {
    // Singleton
    static let shared = SpeechRecognizer()

    private let speechRecognizerJP: SFSpeechRecognizer! = SFSpeechRecognizer(locale: Locale(identifier: "ja_JP"))
    private let speechRecognizerEN: SFSpeechRecognizer! = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))

    private var speechRecognizer: SFSpeechRecognizer {
        switch gameLang {
        case .jp:
            return speechRecognizerJP
        default:
            if let voice = AVSpeechSynthesisVoice(identifier: context.gameSetting.teacher),
                let recognizer = SFSpeechRecognizer(locale: Locale(identifier: voice.language.replacingOccurrences(of: "-", with: "_"))) {
                return recognizer
            }
            return speechRecognizerEN
        }
    }

    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isRunning: Bool = false
    private var isAuthorized: Bool = false
    private var inputNode: AVAudioNode!
    private var promise = Promise<String>.pending()

    override init() {
        super.init()
        let session = AVAudioSession.sharedInstance()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption(notification:)),
                                               name: AVAudioSession.interruptionNotification,
                                               object: session)
        if !isSimulator {
            authorize()
        }
    }

    // MARK: - Public Methods

    func listen(stopAfterSeconds: Double = 5) -> Promise<String> {
        endAudio()
        promise = Promise<String>.pending()
        // mocked start for simulator
        if isSimulator {
            return fakeListening(stopAfterSeconds: stopAfterSeconds)
        }

        guard engine.isEngineRunning else {
            promise.fulfill("Error: SpeechEninge is not started")
            return promise
        }

        if !isAuthorized {
            promise.reject(SpeechRecognitionError.unauthorized)
            showGoToPermissionSettingAlert()
            return promise
        }

        speechRecognizer.defaultTaskHint = .dictation

        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            promise.fulfill("Error: cannot create recognitionRequest")
            return promise
        }

        if #available(iOS 13.0, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }

        recognitionRequest.shouldReportPartialResults = false
        recognitionRequest.taskHint = .dictation

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest, resultHandler: resultHandler)

        guard recognitionTask != nil else {
            promise.fulfill("Error: cannot create recognitionTask")
            return promise
        }

        inputNode = engine.audioEngine.inputNode
        // let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.recognitionRequest?.append(buffer)

            calculateMicLevel(buffer: buffer)
        }

        Timer.scheduledTimer(withTimeInterval: stopAfterSeconds, repeats: false) { _ in
            self.endAudio()
        }

        isRunning = true
        postEvent(.listenStarted, string: "")
        return promise
    }

    // isCanceling is true  => cancel task, discard any said words
    //                false => listen until now, ask apple to return recognized result
    func endAudio(isCanceling: Bool = false) {
        guard isRunning else { return }
        isRunning = false

        guard !isSimulator else { return }

        inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        if isCanceling {
            recognitionTask?.cancel()
        }

        recognitionRequest = nil
        recognitionTask = nil
        postEvent(.listenStopped, string: "")
    }

    // MARK: - Private Methods

    func resultHandler(result: SFSpeechRecognitionResult?, error: Error?) {
        guard engine.isEngineRunning else {
            promise.reject(SpeechRecognitionError.engineStopped)
            return
        }

        if let result = result {
            promise.fulfill(result.bestTranscription.formattedString)
        }

        if let error = error {
            if let userInfo = error._userInfo,
                let desc = (userInfo["NSLocalizedDescription"] as? String) {
                // Retry means didn't hear anything please say again
                if desc == "Retry" {
                    promise.fulfill("")
                } else {
                    promise.fulfill("")
                    _ = getKanaTokenInfos("\(error)")
                    print(error, desc)
                }
                promise.fulfill("")
                return
            }
            _ = getKanaTokenInfos("\(error)")
            print(error)
            promise.fulfill("")
        }
    }

    private func authorize() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                self.isAuthorized = true
                print("Speech Recogntion is authorized")

            case .denied:
                self.isAuthorized = false
                print("User denied access to speech recognition")

            case .restricted:
                self.isAuthorized = false
                print("Speech recognition restricted on this device")

            case .notDetermined:
                self.isAuthorized = false
                print("Speech recognition not yet authorized")
            @unknown default:
                print("\n#### requestAuthorization unknown default ####\n")
            }
        }
    }

    private func fakeListening(stopAfterSeconds: Double = 5) -> Promise<String> {
        isRunning = true
        postEvent(.listenStarted, string: "")
        Timer.scheduledTimer(withTimeInterval: stopAfterSeconds, repeats: false) { [weak self] _ in
            let fakeSuffix = ["", "", "西宮", "はは"]
            let fakeSaidString = context.targetString + fakeSuffix[Int.random(in: 0 ..< fakeSuffix.count)]

            self?.promise.fulfill(fakeSaidString)
        }
        return promise
    }

    // https://stackoverflow.com/questions/48749729/avaudiosession-interruption-on-declining-phone-call
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let interruptionTypeRawValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeRawValue),
            let session = notification.object as? AVAudioSession else {
            print("Recorder - something went wrong")
            return
        }
        switch interruptionType {
        case .began:
            endAudio()
            try? session.setActive(false)
        case .ended:
            try? session.setActive(true)
        }
    }
}
