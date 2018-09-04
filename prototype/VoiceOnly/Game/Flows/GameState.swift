//
//  GameFlow.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on H30/05/05.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//

import Foundation
import Promises

private let context = GameContext.shared
private let pauseDuration = 0.4

enum GameState {
    case stopped
    case TTSSpeaking
    case listening
    case stringRecognized
    case repeatingWhatSaid
    case scoreCalculated
    case speakingScore
    case sentenceSessionEnded
    case gameOver
}

class Game {
    var timer: Timer?
    var isPaused: Bool = false
    var wait: Promise<Void> = Promise<Void>.pending()
    var gameSeconds: Int = 0
    func start() { print("please override game.start method") }
}

extension Game {
    internal func prepareTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.isPaused { return }

            postEvent(.playTimeUpdate, int: self.gameSeconds)
            self.gameSeconds += 1
        }
    }

    internal func gameOver() {
        meijia("遊戲結束").then {
            context.gameState = .gameOver
            self.stop()
        }
    }

    func stop() {
        context.gameRecord?.playDuration = gameSeconds
        context.gameState = .stopped
        timer?.invalidate()
        stopEngine()
    }

    internal func speakTargetString() -> Promise<Void> {
        context.gameState = .TTSSpeaking
        let speakStartedTime = getNow()
        return hattori(context.targetString).then {
            context.speakDuration = getNow() - speakStartedTime
        }
    }

    internal func listen() -> Promise<Void> {
        context.gameState = .listening
        return listenJP(duration: context.speakDuration + pauseDuration)
            .then(saveUserSaidString)
    }

    private func saveUserSaidString(userSaidString: String) -> Promise<Void> {
        context.gameState = .stringRecognized
        context.userSaidString = userSaidString
        return fulfilledVoidPromise()
    }

    internal func getScore() -> Promise<Void> {
        return calculateScore(context.targetString, context.userSaidString)
            .then(saveScore)
    }

    private func saveScore(score: Score) -> Promise<Void> {
        context.gameState = .scoreCalculated
        context.score = score
        updateGameRecord(score: score)
        return fulfilledVoidPromise()
    }

    internal func updateGameRecord(score: Score) {
        context.gameRecord?.sentencesScore[context.targetString] = score

        switch score.type {
        case .perfect:
            context.gameRecord?.perfectCount += 1
        case .great:
            context.gameRecord?.greatCount += 1
        case .good:
            context.gameRecord?.goodCount += 1
        default:
            ()
        }
    }
}
