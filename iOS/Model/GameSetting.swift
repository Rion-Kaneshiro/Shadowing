//
//  GameSetting.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on 9/9/30 H.
//  Copyright © 30 Heisei Lu, WangChou. All rights reserved.
//

import Foundation
import AVFoundation

private let gameSettingKey = "GameSettingKey"
private let context = GameContext.shared

func saveGameSetting() {
   saveToUserDefault(object: context.gameSetting, key: gameSettingKey + gameLang.key)
}

func loadGameSetting() {
    if let gameSetting = loadFromUserDefault(type: GameSetting.self, key: gameSettingKey + gameLang.key) {
        context.gameSetting = gameSetting
    } else {
        print("[\(gameLang)] create new gameSetting")
        context.gameSetting = GameSetting()
    }
}

struct GameSetting: Codable {
    var isAutoSpeed: Bool = true
    var preferredSpeed: Float = AVSpeechUtteranceDefaultSpeechRate
    var practiceSpeed: Float = AVSpeechUtteranceDefaultSpeechRate * 0.75
    var isUsingTranslation: Bool = true
    var isUsingGuideVoice: Bool = true
    var isUsingNarrator: Bool = true
    var narrator: ChatSpeaker = .meijia
    var teacher: ChatSpeaker = .system
    var assisant: ChatSpeaker = .system
}
