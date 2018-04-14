//
//  ViewController.swift
//  PlayThrough
//
//  Created by Wangchou Lu on H30/04/14.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    var session: AVAudioSession = AVAudioSession.sharedInstance()
    var engine: AVAudioEngine = AVAudioEngine()
    var input: AVAudioInputNode!
    var output: AVAudioOutputNode!
    
    func startPlayThrough() {
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try session.setCategory(
                AVAudioSessionCategoryPlayAndRecord,
                mode: AVAudioSessionModeMeasurement//,
                //options: AVAudioSessionCategoryOptions.interruptSpokenAudioAndMixWithOthers
            )
            
            // default  23ms | 1024 frames | <1% CPU (iphone SE)
            // 0.001   0.7ms |   32 frames |  8% CPU
            try session.setPreferredIOBufferDuration(0.001)
            print(session.ioBufferDuration)
            
            session.requestRecordPermission({ (success) in
                if success { print("Permission Granted") } else {
                    print("Permission fail")
                }
            })
            input = engine.inputNode
            output = engine.outputNode
            engine.connect(input, to: output, format: input.outputFormat(forBus: 0))
            engine.prepare()
            try engine.start()
        } catch {
            print("Start Play through failed \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startPlayThrough()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

