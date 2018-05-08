//
//  P1ViewController.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on H30/04/24.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//

import Foundation
import UIKit

// Prototype 1: 全語音、只能用講電話的方式
class P01ViewController: UIViewController, GameEventDelegate {
    let game = VoiceOnlyGame.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startEventObserving(self)
        game.play()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopEventObserving(self)
        game.stop()
    }
    
    @objc func onEventHappened(_ notification: Notification) {
        let event = notification.object as! Event
        switch event.type {
        case .stringSaid:
            print(event.object as! String, terminator: "")
        case .sayEnded:
            print("")
        case .listenStarted:
            print("hear <<< ", terminator: "")
        case .listenEnded:
            print(event.object as! String)
        default:
            return
        }
    }
}
