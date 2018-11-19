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
        let currentLocale = AVSpeechSynthesisVoice.currentLanguageCode()
        context.gameSetting.narrator = AVSpeechSynthesisVoice(language: currentLocale)?.identifier ?? "unknown"
        let langCode = gameLang == .jp ? "ja-JP" : "en-US"

        context.gameSetting.teacher = AVSpeechSynthesisVoice(language: langCode)?.identifier ?? "unknown"
        context.gameSetting.assisant = context.gameSetting.teacher

        print(context.gameSetting.narrator, context.gameSetting.teacher)
    }
}

struct GameSetting: Codable {
    var isAutoSpeed: Bool = true
    var preferredSpeed: Float = AVSpeechUtteranceDefaultSpeechRate
    var practiceSpeed: Float = AVSpeechUtteranceDefaultSpeechRate * 0.75
    var isUsingTranslation: Bool = true
    var isUsingGuideVoice: Bool = true
    var isUsingNarrator: Bool = true
    var isMointoring: Bool = false
    var narrator: String = "unknown"
    var teacher: String = "unknown"
    var assisant: String = "unknown"
    var dailySentenceGoal: Int = 50
}
