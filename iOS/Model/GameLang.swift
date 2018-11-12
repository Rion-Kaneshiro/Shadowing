//
//  GameLang.swift
//  今話したい
//
//  Created by Wangchou Lu on 11/2/30 H.
//  Copyright © 30 Heisei Lu, WangChou. All rights reserved.
//

private let gameLangKey = "GameLangKey"

func saveGameLang() {
    saveToUserDefault(object: gameLang, key: gameLangKey)
}

func loadGameLang() {
    if let loadedGameLang = loadFromUserDefault(type: Lang.self, key: gameLangKey) {
        gameLang = loadedGameLang
    }
}

var jaSentenceInfos: [Int: SentenceInfo] = [:]
var enSentenceInfos: [Int: SentenceInfo] = [:]

enum Lang: Int, Codable {
    case jp = 0
    case en = 1

    var key: String {
        if self == .jp { return "" }
        if self == .en { return "en" }
        return ""
    }
    var isSupportTopicMode: Bool {
        if self == .jp { return true }
        return false
    }

    var sentenceInfos: [Int: SentenceInfo] {
        switch self {
        case .jp:
            return jaSentenceInfos
        case .en:
            return enSentenceInfos
        }
    }
}

var gameLang: Lang = Lang.jp
