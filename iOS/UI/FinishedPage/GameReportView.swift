//
//  ReportView.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on 6/7/30 H.
//  Copyright © 30 Heisei Lu, WangChou. All rights reserved.
//

import Foundation
import UIKit

private let context = GameContext.shared

var countDownTimer: Timer?
var pauseOrPlayButton: UIButton?
private var isPauseMode: Bool = true

func stopCountDown() {
    countDownTimer?.invalidate()
    pauseOrPlayButton?.setIconImage(named: "baseline_play_arrow_black_48pt", title: "", tintColor: .white, isIconOnLeft: false)
    pauseOrPlayButton = nil
    isPauseMode = false
}

@IBDesignable
class GameReportView: UIView, ReloadableView, GridLayout {
    let gridCount = 48
    let axis: GridAxis = .horizontal
    let spacing: CGFloat = 0
    var reportBox: GameReportBoxView?

    func viewWillAppear() {
        removeAllSubviews()
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        reportBox = GameReportBoxView()

        if context.contentTab == .topics {
            frame = CGRect(x: 0, y: 0, width: screen.width, height: screen.width * 1.38)
            layout(2, 4, 44, 50, reportBox!)
        } else {
            frame = CGRect(x: 0, y: 0, width: screen.width, height: screen.width * 1.17)
            layout(2, 4, 44, 40, reportBox!)
        }

        addReloadableSubview(reportBox!)
        pauseOrPlayButton = addNextGameButton()
        addBackButton()
    }

    func viewDidAppear() {
        reportBox?.animateProgressBar()
    }

    func viewDidDisappear() {
        countDownTimer?.invalidate()
        pauseOrPlayButton = nil
    }

    func createButton(title: String, bgColor: UIColor) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .highlighted)
        button.backgroundColor = bgColor
        button.titleLabel?.font = MyFont.regular(ofSize: step * 4)
        button.titleLabel?.textColor = myLightGray
        button.roundBorder(borderWidth: 1, cornerRadius: 5, color: .clear)
        return button
    }

    func addNextGameButton() -> UIButton {
        isPauseMode = true
        let button = createButton(title: "", bgColor: .red)
        let todaySentenceCount = getTodaySentenceCount()
        let dailyGoal = context.gameSetting.dailySentenceGoal
        var isReachDailyByThisGame = false
        if let record = context.gameRecord {
            isReachDailyByThisGame = todaySentenceCount >= dailyGoal &&
                                     todaySentenceCount - record.correctCount < dailyGoal
        }
        let countDownSecs = isReachDailyByThisGame ? 7 : 5
        button.setIconImage(named: "baseline_pause_black_48pt", title: " 次の挑戦 (\(countDownSecs)秒)", tintColor: .white, isIconOnLeft: true)
        button.addTapGestureRecognizer {
            if isPauseMode {
                stopCountDown()
            } else {
                dismissTwoVC(animated: false) {
                    launchNextGame()
                }
            }
        }

        if context.contentTab == .topics {
            layout(2, 56, 28, 8, button)
        } else {
            layout(2, 46, 28, 8, button)
        }

        addSubview(button)
        var leftSeconds = countDownSecs
        countDownTimer = Timer.scheduledTimer(withTimeInterval: 1.00, repeats: true) { _ in
            leftSeconds -= 1
            pauseOrPlayButton?.setTitle(" 次の挑戦 (\(leftSeconds)秒)", for: .normal)
            guard leftSeconds > 0 else {
                countDownTimer?.invalidate()
                dismissTwoVC(animated: false) {
                    launchNextGame()
                }
                return
            }
        }

        return button
    }

    func addBackButton() {
        let backButton = createButton(title: "", bgColor: .lightGray)
        backButton.setIconImage(named: "baseline_exit_to_app_black_48pt", title: "", tintColor: .white, isIconOnLeft: false)

        backButton.addTapGestureRecognizer {
            stopCountDown()
            dismissTwoVC()
            if context.contentTab == .infiniteChallenge {
                if let icwPage = rootViewController.current as? InfiniteChallengeSwipablePage {
                    (icwPage.pages[2] as? InfiniteChallengePage)?.tableView.reloadData()
                }
            }
        }

        if context.contentTab == .topics {
            layout(32, 56, 14, 8, backButton)
        } else {
            layout(32, 46, 14, 8, backButton)
        }

        addSubview(backButton)
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        viewWillAppear()
    }
}

private func launchNextGame() {
    if context.contentTab == .topics && !context.gameSetting.isRepeatOne {
        context.loadNextChallenge()
        let pages = rootViewController.mainSwipablePage.pages
        if pages.count > 2,
            let topicDetailPage = pages[2] as? TopicDetailPage {
            topicDetailPage.render()
        }
    }
    if isUnderDailySentenceLimit() {
        guard let vc = UIApplication.getPresentedViewController() else { return }
        launchStoryboard(vc, "MessengerGame")
    }
}
