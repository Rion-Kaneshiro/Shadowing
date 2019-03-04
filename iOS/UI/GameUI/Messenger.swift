//
//  P8ViewController.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on H30/05/05.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//

import AVFoundation
import UIKit

private let context = GameContext.shared

enum LabelPosition {
    case left
    case center
    case right
}

// Prototype 8: messenger / line interface
class Messenger: UIViewController {
    var lastLabel: FuriganaLabel = FuriganaLabel()

    private var y: Int = 8
    private var previousY: Int = 0

    @IBOutlet weak var levelMeterView: UIView!
    @IBOutlet weak var levelMeterValueBar: UIView!
    @IBOutlet weak var scrollView: UIScrollView!

    // pauseOverlay
    @IBOutlet weak var overlayView: UIView!
    @IBOutlet weak var speedSlider: UISlider!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var autoSpeedSwitch: UISwitch!
    @IBOutlet weak var learningModeLabel: UILabel!
    @IBOutlet weak var learningModeSegmentControl: UISegmentedControl!
    @IBOutlet weak var repeatOneSwitchButton: UIButton!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var fastLabel: UILabel!
    @IBOutlet weak var autoSpeedLabel: UILabel!

    @IBOutlet weak var messengerBar: MessengerBar!
    let spacing = 15

    override func viewDidLoad() {
        super.viewDidLoad()

        // in case there is no network for VerifyReceipt when app launch.
        if !isEverReceiptProcessed {
            IAPHelper.shared.processReceipt()
        }

        // OverlayView
        overlayView.isHidden = true
        exitButton.layer.cornerRadius = 5
        // prevent events pass to back view
        speedSlider.addTapGestureRecognizer(action: nil)
        overlayView.addTapGestureRecognizer(action: continueGame)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        start()
        UIApplication.shared.isIdleTimerDisabled = true
        scrollView.delaysContentTouches = false
        levelMeterValueBar.roundBorder(borderWidth: 0, cornerRadius: 4.5, color: .clear)
        levelMeterValueBar.frame.size.height = 0
        levelMeterView.isUserInteractionEnabled = false
        messengerBar.viewWillAppear()
        messengerBar.initData()
        renderOverlayView()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        scrollView.removeAllSubviews()
        end()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func start() {
        startEventObserving(self)
        GameFlow.shared.start()

        scrollView.addTapGestureRecognizer(action: pauseContinueGame)
        messengerBar.addTapGestureRecognizer(action: pauseContinueGame)
        messengerBar.pauseCountinueButton.addTarget(self, action: #selector(pauseContinueGame), for: .touchUpInside)
        messengerBar.skipNextButton.addTarget(self, action: #selector(skipNext), for: .touchUpInside)
    }

    func end() {
        stopEventObserving(self)
    }

    func renderOverlayView() {
        let i18n = I18n.shared

        autoSpeedLabel.text = i18n.autoSpeedLabel
        speedLabel.text = i18n.speed

        speedSlider.minimumValue = AVSpeechUtteranceMinimumSpeechRate
        speedSlider.maximumValue = AVSpeechUtteranceMaximumSpeechRate * 0.75

        autoSpeedSwitch.isOn = context.gameSetting.isAutoSpeed
        speedSlider.value = context.gameSetting.preferredSpeed
        fastLabel.text = String(format: "%.2fx", context.gameSetting.preferredSpeed*2)
        if context.gameSetting.isAutoSpeed {
            speedSlider.isEnabled = false
            fastLabel.textColor = UIColor.lightGray
            speedLabel.textColor = UIColor.gray
        } else {
            speedSlider.isEnabled = true
            fastLabel.textColor = UIColor.white
            speedLabel.textColor = UIColor.white
        }

        if context.contentTab == .topics {
            repeatOneSwitchButton.isHidden = false
        } else {
            repeatOneSwitchButton.isHidden = true
        }

        repeatOneSwitchButton.roundBorder(borderWidth: 0, cornerRadius: 25, color: .clear)

        if context.gameSetting.isRepeatOne {
            repeatOneSwitchButton.tintColor = UIColor.white
            repeatOneSwitchButton.backgroundColor = myOrange.withSaturation(1)
        } else {
            repeatOneSwitchButton.tintColor = UIColor.white.withBrightness(0.7)
            repeatOneSwitchButton.backgroundColor = UIColor.white.withBrightness(0.5)
        }

        initLearningModeSegmentControl(label: learningModeLabel, control: learningModeSegmentControl)
    }

    func prescrolling(_ text: NSAttributedString, pos: LabelPosition = .left) {
        let originalPreviousY = previousY
        let originalY = y
        let originalLastLabel = lastLabel

        addLabel(text, isAddSubview: false)

        // center echo text
        if context.gameSetting.learningMode == .echoMethod {
            let echoText = rubyAttrStr(i18n.listenToEcho)
            addLabel(echoText, pos: .center, isAddSubview: false)
        }

        // right text
        let dotText = rubyAttrStr("...")
        addLabel(dotText, pos: .right, isAddSubview: false)
        previousY = originalPreviousY
        y = originalY
        lastLabel = originalLastLabel
    }

    func addLabel(_ text: NSAttributedString, pos: LabelPosition = .left, isAddSubview: Bool = true) {
        let myLabel = FuriganaLabel()
        updateLabel(myLabel, text: text, pos: pos)
        if isAddSubview {
            scrollView.addSubview(myLabel)
        }
        lastLabel = myLabel
    }

    func updateLabel(_ myLabel: FuriganaLabel, text: NSAttributedString, pos: LabelPosition) {
        let maxLabelWidth: Int = Int(screen.width*3/4)

        var height = 30
        var width = 10
        myLabel.attributedText = text

        // sizeToFit is not working here... T.T
        height = Int(myLabel.heightOfCoreText(attributed: text, width: CGFloat(maxLabelWidth)))
        width = Int(myLabel.widthOfCoreText(attributed: text, maxWidth: CGFloat(maxLabelWidth)))

        myLabel.frame = CGRect(x: 5, y: y, width: width, height: height)

        myLabel.roundBorder()

        switch pos {
        case .left:
            myLabel.backgroundColor = myWhite
        case .right:
            myLabel.frame.origin.x = CGFloat(Int(screen.width) - 5 - Int(myLabel.frame.width))
            if text.string == "..." {
                myLabel.backgroundColor = .gray
            } else if text.string == i18n.iCannotHearYou {
                myLabel.backgroundColor = myRed
            } else {
                myLabel.backgroundColor = myGreen
            }
        case .center:
            myLabel.backgroundColor = .clear
            myLabel.centerX(scrollView.frame)
            myLabel.alpha = 0.5
        }

        previousY = y
        y += Int(myLabel.frame.height) + spacing

        if pos == .right {
            scrollView.scrollTo(y)
        }
    }

    func updateLastLabelText(_ text: NSAttributedString, pos: LabelPosition = .left) {
        y = previousY
        updateLabel(lastLabel, text: text, pos: pos)
    }

    @objc func pauseContinueGame() {
        if messengerBar.isGameStopped {
            continueGame()
        } else {
            messengerBar.isGameStopped = true
            messengerBar.viewWillAppear()
            postCommand(.pause)
            overlayView.isHidden = false

        }
    }

    @objc func skipNext() {
        // TODO check next level is accessible for infiniteChallenge Mode

        postCommand(.forceStopGame)
        self.dismiss(animated: true) {
            if context.contentTab == .topics {
                context.loadNextChallenge()
                let pages = rootViewController.mainSwipablePage.pages
                if pages.count > 2,
                    let topicDetailPage = pages[2] as? TopicDetailPage {
                    topicDetailPage.render()
                }
            }
            guard let vc = UIApplication.getPresentedViewController() else { return }
            launchStoryboard(vc, "MessengerGame")
        }
    }

    @objc func continueGame() {
        overlayView.isHidden = true
        postCommand(.resume)
    }

    // pauseOverlay actions
    @IBAction func speedChanged(_ sender: Any) {
        context.gameSetting.preferredSpeed = speedSlider.value
        saveGameSetting()
        renderOverlayView()
    }
    @IBAction func autoSpeedSwitchValueChanged(_ sender: Any) {
        context.gameSetting.isAutoSpeed = autoSpeedSwitch.isOn
        saveGameSetting()
        renderOverlayView()
    }
    @IBAction func learningModeSegmentControlValueChanged(_ sender: Any) {
        actOnLearningModeSegmentControlValueChanged(control: learningModeSegmentControl)
    }
    @IBAction func repeatOneSwitchButtonClicked(_ sender: Any) {
        context.gameSetting.isRepeatOne = !context.gameSetting.isRepeatOne
        saveGameSetting()
        renderOverlayView()
    }
    @IBAction func exitButtonClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        postCommand(.forceStopGame)
    }
}
