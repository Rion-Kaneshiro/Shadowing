//
//  constants.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on H30/04/19.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//

import Foundation
import AVFoundation

let MeiJia = "com.apple.ttsbundle.Mei-Jia-compact"
let Otoya = "com.apple.ttsbundle.Otoya-premium"
let Kyoko = "com.apple.ttsbundle.Kyoko-premium"
let Oren = "com.apple.ttsbundle.siri_female_ja-JP_compact"
let Hattori = "com.apple.ttsbundle.siri_male_ja-JP_compact"

let I_SAY_YOU_SAY = "接下來，我說一句日文，你跟著說一句"
let CANNOT_HEAR_HINT = "聽不清楚、再一次。"
let I_HEAR_YOU_HINT = "我聽到你說："
let SPEAK_TO_ME_HINT = "請說日文給我聽"
let REPEAT_AFTER_ME_HINT = "請跟著唸日文"

let HARUHI = "ただの人間には興味ありません。この中に宇宙人、未来人、異世界人、超能力者がいたら、あたしのところに来なさい。以上。"

let normalRate = AVSpeechUtteranceDefaultSpeechRate
let teachingRate = AVSpeechUtteranceDefaultSpeechRate * 0.7
let slowestRate = AVSpeechUtteranceDefaultSpeechRate * 0.6

// it's bad when monitoring at street
// if in quite place. turn micOutVolume to 3
let micOutVolume: Float = 0

var sentences: [String] = [
    "安い",
    "いいね",
    "すごい",
    "はじめまして",
    "こんにちは",
    "真実はいつもひとつ！",
    "わたし、気になります！",
    "おまえはもう死んでる",
    "わーい！たーのしー！すごい！",
    "頑張ります！",
]
