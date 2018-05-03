//
//  SayCommand.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on H30/05/03.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//

import Foundation
import Speech

struct SayCommand: Command {
    let type = CommandType.say
    let text: String
    let name: String
    let rate: Float
    let delegate: AVSpeechSynthesizerDelegate?
    
    func exec() {
        let context = Commands.shared
        if !context.isEngineRunning {
            return
        }
        cmdGroup.enter()
        context.tts.say(text, name, rate: rate, delegate: delegate) {
            if(self.name == Hattori ) {
                context.bgm.restoreVolume()
            }
            cmdGroup.leave()
        }
    }
    
    func log() {
        switch self.name {
        case MeiJia:
            print("美佳 🇹🇼: ", terminator: "")
        case Hattori:
            print("服部 🇯🇵: ", terminator: "")
        case Oren:
            print("オーレン 🇯🇵: ", terminator: "")
        default:
            return
        }
    }
}

// for keeping the default memberwise initializer
extension SayCommand {
    init(_ text: String, _ name: String, rate: Float, delegate: AVSpeechSynthesizerDelegate?) {
        self.init(text: text, name: name, rate: rate, delegate: delegate)
    }
}

func meijia(_ sentence: String) {
    dispatch(SayCommand(sentence, MeiJia, rate: normalRate, delegate: nil))
}

func oren(_ sentence: String, rate: Float = teachingRate, delegate: AVSpeechSynthesizerDelegate? = nil) {
    dispatch(SayCommand(sentence, Oren, rate: rate, delegate: delegate))
}

func hattori(_ sentence: String, rate: Float = teachingRate, delegate: AVSpeechSynthesizerDelegate? = nil) {
    dispatch(SayCommand(sentence, Hattori, rate: rate, delegate: delegate))
}
