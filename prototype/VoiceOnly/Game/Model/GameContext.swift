//
//  AudioController.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on H30/04/24.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//

import Foundation
import Promises
import UIKit
import AVFoundation

enum GameUIMode {
    case phone, messenger, console, reader
}

enum GameFlowMode {
    case shadowing, chat
}

class GameContext {
    // MARK: - Singleton
    static let shared = GameContext()

    private init() {}

    // MARK: - Long-term data will be kept in UserDefault
    var gameHistory = [GameRecord]()
    var gameCharacter: GameCharacter = GameCharacter()
    var characterImage: UIImage?

    // MARK: - Short-term data of a single game
    var gameUIMode: GameUIMode = .messenger
    var gameFlowMode: GameFlowMode = .chat
    var isTargetSentencePlayedByUser: Bool {
        return gameFlowMode == .chat && userPlayedCharacter == targetSpeaker
    }
    var gameState: GameState = .stopped {
        didSet {
            postEvent(.gameStateChanged, gameState: gameState)
        }
    }
    var userPlayedCharacter: ChatSpeaker = .woman1
    var dataSetKey: String = "" // the sentence set key in current game
    var gameRecord: GameRecord? // of current game
    var isEngineRunning: Bool {
        return GameEngine.shared.isEngineRunning
    }
    var life: Int = 40
    var startTime: Double = getNow()
    var teachingRate: Float {
        return AVSpeechUtteranceDefaultSpeechRate * (0.5 + life.f * 0.005)
    }
    var isNewRecord = false
    var sentences: [(speaker: ChatSpeaker, string: String)] = []
    var userSaidSentences: [String: String] = [:]
    var sentenceIndex: Int = 0
    var remainingSentenceCount: Int {
        return sentences.count - sentenceIndex
    }

    // MARK: - Short-term data for a single sentence
    var targetString: String {
        guard sentenceIndex < sentences.count else { return ""}
        return sentences[sentenceIndex].string
    }
    var targetSpeaker: ChatSpeaker {
        guard sentenceIndex < sentences.count else { return ChatSpeaker.man1 }
        return sentences[sentenceIndex].speaker
    }
    var speakDuration: Promise<Float> {
        let duration: Promise<Float> = Promise<Float>.pending()
        getKana(targetString).then({ kana in
            duration.fulfill(0.5 + kana.count.f * 0.12 / (0.5 + self.life.f * 0.005))
        })
        return duration
    }
    var userSaidString: String {
        get {
            return userSaidSentences[self.targetString] ?? ""
        }

        set {
            userSaidSentences[self.targetString] = newValue
        }
    }
    var score: Score = Score(value: 0)

    // MARK: - functions for a single game
    func loadLearningSentences(isShuffle: Bool = false) {
        sentenceIndex = 0
        guard let selectedDataSet = allSentences[dataSetKey] else { return }
        sentences = isShuffle ? selectedDataSet.shuffled() : selectedDataSet
        userSaidSentences = [:]

        life = isSimulator ? 100 : 40

        let level = allLevels[dataSetKey] ?? .n5a
        gameRecord = GameRecord(dataSetKey, sentencesCount: sentences.count, level: level)

        isNewRecord = false
    }

    func nextSentence() -> Bool {
        sentenceIndex += 1
        var sentencesBound = sentences.count
        if isSimulator {
            sentencesBound = 5
        }
        guard sentenceIndex < sentencesBound else { return false }
        userSaidString = ""
        return true
    }
}
