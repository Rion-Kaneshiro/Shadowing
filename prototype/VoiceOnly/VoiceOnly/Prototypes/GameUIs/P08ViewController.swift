//
//  P8ViewController.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on H30/05/05.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//

import Foundation
import UIKit

extension P08ViewController: GameEventDelegate {
    @objc func onEventHappened(_ notification: Notification) {
        let event = notification.object as! Event
        
        switch event.type {
        case .sayStarted:
            guard let name = event.string else {
                return
            }
            switch name {
            case MeiJia:
                if game.state == .stopped {
                    addLabel("")
                }
            case Hattori:
                addLabel("")
            default:
                return
            }
            
        case .stringSaid:
            guard let saidWord = event.string else { return }
            if game.state == .speakingJapanese || game.state == .stopped {
                updateLastLabelText(lastLabel.text! + saidWord)
            }
            
        case .listenStarted:
            addLabel("", isLeft: false)
            
        case .stringRecognized, .listenEnded:
            guard var saidString = event.string else { return }
            if(event.type == .listenEnded && saidString == "") {
                saidString = "聽不清楚"
            }
            updateLastLabelText(saidString, isLeft: false)
            
        case .scoreCalculated:
            guard let score = event.int else { return }
            var newText = "\(lastLabel.text!) \(score)分"
            newText = score == 100 ? "\(newText) ⭐️" : newText
            updateLastLabelText(newText, isLeft: false)
            
            if score < 60 {
                lastLabel.backgroundColor = myRed
            }
            
        default:
            return
        }
    }
}

// Prototype 8: messenger / line interface
class P08ViewController: UIViewController {
    let game = SimpleGame.shared
    let spacing: Int = 8
    var y: Int = 8
    var previousY: Int = 0
    var lastLabel: UITextView = UITextView()
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    func addLabel(_ text: String, isLeft: Bool = true) {
        let myLabel = UITextView()
        updateLabel(myLabel, text: text, isLeft: isLeft)
        scrollView.addSubview(myLabel)
        lastLabel = myLabel
    }
    
    func updateLabel(_ myLabel: UITextView, text: String, isLeft: Bool = true) {
        let maxLabelWidth: Int = Int(screenSize.width*2/3)
        
        myLabel.text = text
        myLabel.textContainerInset = UIEdgeInsetsMake(4, 4, 4, 4)
        myLabel.layer.borderWidth = 1.5;
        myLabel.font = UIFont.systemFont(ofSize: 20)
        if isLeft {
            myLabel.backgroundColor = .white
        } else {
            myLabel.backgroundColor = myGreen
        }
        myLabel.frame = CGRect(x: 5, y: y, width: maxLabelWidth, height: 30)
        myLabel.sizeToFit()
        myLabel.clipsToBounds = true
        myLabel.layer.cornerRadius = 15.0
        
        previousY = y
        y = y + Int(myLabel.frame.height) + spacing
        
        if(!isLeft) {
            myLabel.frame.origin.x = CGFloat(Int(screenSize.width) - spacing - Int(myLabel.frame.width))
        }
        
        scrollView.contentSize = CGSize(
            width: scrollView.frame.size.width,
            height: max(scrollView.frame.size.height, CGFloat(y))
        )
        scrollView.scrollRectToVisible(CGRect(x: 5, y: y-1, width: 1, height: 1), animated: true)
    }
    
    func updateLastLabelText(_ text: String, isLeft: Bool = true) {
        y = previousY
        updateLabel(lastLabel, text: text, isLeft: isLeft)
    }
    
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
}
