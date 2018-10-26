//
//  P8ViewController.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on H30/05/05.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//

import Foundation
import UIKit

private let context = GameContext.shared

// Prototype 8: messenger / line interface
class Messenger: UIViewController {
    var game: ShadowingFlow?
    var lastLabel: FuriganaLabel = FuriganaLabel()

    private var y: Int = 8
    private var previousY: Int = 0

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var sentenceCountLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    let spacing = 15

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        start()
        UIApplication.shared.isIdleTimerDisabled = true
        scrollView.delaysContentTouches = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scrollView.removeAllSubviews()
        end()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func start() {
        startEventObserving(self)
        game = ShadowingFlow()
        game?.start()
        sentenceCountLabel.text = "還有\(context.sentences.count)句"
        speedLabel.text = String(format: "%.2f 倍速", context.teachingRate * 2)
        timeLabel.text = "00:00"
        context.startTime = getNow()

        scrollView.addTapGestureRecognizer(action: scrollViewTapped)
    }

    func end() {
        stopEventObserving(self)
        game = nil
    }

    func addLabel(_ text: NSAttributedString, isLeft: Bool = true) {
        let myLabel = FuriganaLabel()
        updateLabel(myLabel, text: text, isLeft: isLeft)
        scrollView.addSubview(myLabel)
        lastLabel = myLabel
    }

    func updateLabel(_ myLabel: FuriganaLabel, text: NSAttributedString, isLeft: Bool = true) {
        let maxLabelWidth: Int = Int(screen.width*3/4)

        var height = 30
        var width = 10
        myLabel.attributedText = text

        // sizeToFit is not working here... T.T
        height = Int(myLabel.heightOfCoreText(attributed: text, width: CGFloat(maxLabelWidth)))
        width = Int(myLabel.widthOfCoreText(attributed: text, maxWidth: CGFloat(maxLabelWidth)))

        myLabel.frame = CGRect(x: 5, y: y, width: width, height: height)

        myLabel.roundBorder()

        if isLeft {
            myLabel.backgroundColor = myWhite
        } else {
            myLabel.frame.origin.x = CGFloat(Int(screen.width) - 5 - Int(myLabel.frame.width))
            if text.string == "..." {
                myLabel.backgroundColor = .gray
            } else if text.string == "聽不清楚" {
                myLabel.backgroundColor = myRed
            } else {
                myLabel.backgroundColor = myGreen
            }
        }

        previousY = y
        y += Int(myLabel.frame.height) + spacing

        scrollView.scrollTo(y)
    }

    func updateLastLabelText(_ text: NSAttributedString, isLeft: Bool = true) {
        y = previousY
        updateLabel(lastLabel, text: text, isLeft: isLeft)
    }

    @objc func scrollViewTapped() {
        postCommand(.pause)
        launchStoryboard(self, "PauseOverlay", isOverCurrent: true)
    }
}
