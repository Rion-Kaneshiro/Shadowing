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

enum GameFlowMode: String, Codable {
    case shadowing, chat
}

enum ContentTab: String, Codable {
    case topics, infiniteChallenge
}

class GameContext {
    // MARK: - Singleton
    static let shared = GameContext()

    private init() {}

    // MARK: - Long-term data will be kept in UserDefault
    var gameHistory = [GameRecord]()
    var characterImage: UIImage?
    var gameSetting = GameSetting()

    // MARK: - Short-term data of a single game
    var contentTab: ContentTab = .topics
    var infiniteChallengeLevel: Level = .lv0
    var gameState: GameState = .justStarted {
        didSet {
            postEvent(.gameStateChanged, gameState: gameState)
        }
    }
    var dataSetKey: String = "" // the sentence set key in current game
    var gameRecord: GameRecord? // of current game
    var isEngineRunning: Bool {
        return SpeechEngine.shared.isEngineRunning
    }
    var startTime: Double = getNow()
    var life: Int = 50

    var teachingRate: Float {
        if !gameSetting.isAutoSpeed {
            return gameSetting.preferredSpeed
        }
        if contentTab == .infiniteChallenge,
           let level = gameRecord?.level {
                return AVSpeechUtteranceDefaultSpeechRate * (0.6 + Float(level.rawValue) * 0.05)

        }
        return AVSpeechUtteranceDefaultSpeechRate * (0.4 + life.f * 0.007)
    }
    var isNewRecord: Bool {
        return gameRecord?.isNewRecord ?? false
    }
    var newRecordIncrease: Int = 0
    var sentences: [String] = []
    var sentenceIndex: Int = 0

    // MARK: - Short-term data for a single sentence
    var targetString: String {
        guard sentenceIndex < sentences.count else { return ""}
        return sentences[sentenceIndex]
    }

    // Real duration in seconds of tts speaking
    var speakDuration: Float = 0

    // Calculated duration when guide voice off mode
    var calculatedSpeakDuration: Promise<Float> {
        let duration: Promise<Float> = Promise<Float>.pending()
        getKana(targetString).then({ kana in
            duration.fulfill(
                1.0 +
                kana.count.f * 0.13 /
                (self.teachingRate/AVSpeechUtteranceDefaultSpeechRate)
            )
        })
        return duration
    }

    var userSaidString: String {
        get { return userSaidSentences[self.targetString] ?? "" }
        set { userSaidSentences[self.targetString] = newValue }
    }
    var score: Score = Score(value: 100)

    // MARK: - functions for a single game
    func loadLearningSentences() {
        if contentTab == .topics {
            loadTopicSentence()
        } else {
            loadInfiniteChallengeLevelSentence()
        }
    }

    private func loadTopicSentence() {
        sentenceIndex = 0
        guard let selectedDataSet = dataSets[dataSetKey] else { return }
        sentences = selectedDataSet

        life = isSimulator ? 100 : 50

        let level = dataKeyToLevels[dataSetKey] ?? .lv0
        gameRecord = GameRecord(dataSetKey, sentencesCount: sentences.count, level: level)
    }

    private func loadInfiniteChallengeLevelSentence() {
        let level = infiniteChallengeLevel
        sentenceIndex = 0
        dataSetKey = level.infinteChallengeDatasetKey
        loadSentenceDB()
        let numOfSentences = isSimulator ? 3 : 20
        let sentenceIds = randSentenceIds(
            minKanaCount: level.minSyllablesCount,
            maxKanaCount: level.maxSyllablesCount,
            numOfSentences: numOfSentences
        )

        sentences = getSentencesByIds(ids: sentenceIds)

        if gameLang == .jp {
            sentences.forEach { s in
                _ = s.furiganaAttributedString // load furigana
            }
        }
        
        if isSimulator { life = 100 }
        gameRecord = GameRecord(dataSetKey, sentencesCount: sentences.count, level: level)

    }

    func nextSentence() -> Bool {
        sentenceIndex += 1
        let sentencesBound = isSimulator ? 3 : sentences.count
        guard sentenceIndex < sentencesBound else { return false }
        userSaidString = ""
        return true
    }
}
