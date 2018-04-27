//
//  ReplayUnit.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on H30/04/17.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//

import Foundation
import AVFoundation

class ReplayUnit {
    public var node = AVAudioPlayerNode()

    func play(completionHandler: @escaping () -> Void = {}) {
        do {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as NSString
            let url = NSURL.init(string: path .appendingPathComponent("audio.caf"))
            let file = try AVAudioFile(forReading: url! as URL)
            let buffer: AVAudioPCMBuffer! = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: UInt32(file.length))
            try file.read(into: buffer)
            node.scheduleBuffer(buffer, completionHandler: completionHandler)
            node.play()
        } catch {
            print("ReplayUnit play error \(error)")
        }
    }
}
