//
//  MedalGamePage.swift
//  今話したい
//
//  Created by Wangchou Lu on 3/26/31 H.
//  Copyright © 31 Heisei Lu, WangChou. All rights reserved.
//

import Foundation
import UIKit

private let context = GameContext.shared

@IBDesignable
class MedalPageView: UIView, ReloadableView, GridLayout {
    var gridCount: Int = 48

    var axis: GridAxis = .horizontal

    var spacing: CGFloat = 0

    var yMax: Int {
        return Int(screen.height / stepFloat)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        sharedInit()
    }

    func sharedInit() {
        self.clipsToBounds = true
        self.frame = CGRect(x: 0, y: 0, width: screen.width, height: screen.height)
    }

    func viewWillAppear() {
        removeAllSubviews()
        drawTextBackground(bgColor: rgb(60, 60, 60), textColor: textGold)
        addTopBar(y: 5)

        addLangInfo(y: (yMax + 12)/2 - 22 - 1)
        addGoButton(x: 25, y: (yMax + 12)/2 - 22 + 24, w: 21)
    }

    private func addTopBar(y: Int) {
        func addButton(iconName: String) -> UIButton {
            let button = createButton(title: "", bgColor: myOrange)
            button.setIconImage(named: iconName, tintColor: .black, isIconOnLeft: false)
            button.roundBorder(borderWidth: stepFloat/2, cornerRadius: stepFloat,
                               color: rgb(35, 35, 35))
            addSubview(button)
            return button
        }

        var iconPX = "24pt"
        if isIPad { iconPX = "48pt"}

        let leftButton = addButton(iconName: "outline_settings_black_\(iconPX)")
        layout(3, y, 7, 7, leftButton)
        leftButton.addTapGestureRecognizer {
            (rootViewController.current as? UIPageViewController)?.goToPreviousPage()
        }

        let rightButton = addButton(iconName: "outline_all_inclusive_black_\(iconPX)")
        layout(38, y, 7, 7, rightButton)

        rightButton.addTapGestureRecognizer {
            (rootViewController.current as? UIPageViewController)?.goToNextPage()
        }

        // total medal counts
        let outerRect = addRect(x: 13, y: y, w: 22, h: 7,
                                color: UIColor.white.withAlphaComponent(0.15))
        outerRect.roundBorder(borderWidth: stepFloat/2, cornerRadius: stepFloat,
                              color: UIColor.black.withAlphaComponent(0.8))

        let medalView = MedalView()
        layout(15, y + 2, 4, 4, medalView)
        medalView.centerY(outerRect.frame)
        medalView.viewWillAppear()
        addSubview(medalView)

        let starAttrStr = getStrokeText("\(context.gameMedal.totalCount)".padWidthTo(4),
                                        myOrange,
                                        strokeWidth: Float(stepFloat * -3/5),
                                        font: MyFont.heavyDigit(ofSize: 5 * stepFloat))
        let label = addAttrText(x: 19, y: y - 1, w: 14, h: 9, text: starAttrStr)
        label.textAlignment = .center
    }

    @objc func onChangeLangButtonClicked() {
        changeGameLangTo(lang: gameLang == .jp ? .en : .jp)
        self.viewWillAppear()
    }

    private func addLangInfo(y: Int) {
        let medal = context.gameMedal

        // changeLangButton
        let changeLangButton = UIButton()
        changeLangButton.backgroundColor = UIColor.white.withAlphaComponent(0.4)
        changeLangButton.roundBorder(borderWidth: 0, cornerRadius: stepFloat, color: .clear)
        var attrTitle = getStrokeText(gameLang == .jp ? "英" : "日",
                                      rgb(200, 200, 200),
                                      strokeWidth: Float(stepFloat * -1/3),
                                      font: MyFont.bold(ofSize: 4*stepFloat))

        changeLangButton.setAttributedTitle(attrTitle, for: .normal)
        layout(34, y, 8, 5, changeLangButton)
        changeLangButton.addTarget(self, action: #selector(onChangeLangButtonClicked), for: .touchUpInside)
        changeLangButton.showsTouchWhenHighlighted = true
        addSubview(changeLangButton)

        // Title
        let rect = addRect(x: 3, y: y+10, w: 42, h: 28, color: UIColor.black.withAlphaComponent(0.4))
        rect.roundBorder(borderWidth: 0, cornerRadius: stepFloat * 2, color: .clear)
        attrTitle = getStrokeText(gameLang == .jp ? "日本語" : "英語",
                                  .white,
                                  strokeWidth: Float(stepFloat * -1/3),
                                  font: MyFont.bold(ofSize: 9*stepFloat))

        let label = addAttrText(x: 7, y: y+4, h: 13, text: attrTitle)
        label.sizeToFit()

        addMedalProgressBar(x: 7, y: y + 13, medalFrom: medal.count)
        addDailyGoalView(x: 7, y: y + 25)
    }

    private func addDailyGoalView(x: Int, y: Int) {
        let todayPercent = getTodaySentenceCount().f/context.gameSetting.dailySentenceGoal.f

        let dailyGoalView = ProgressCircleView()
        layout(x, y, 8, 8, dailyGoalView)
        addSubview(dailyGoalView)
        dailyGoalView.percent = todayPercent
        dailyGoalView.title = i18n.goalText
        dailyGoalView.lvl = context.gameMedal.lowLevel
        dailyGoalView.viewWillAppear()
    }

    private func addGoButton(x: Int, y: Int, w: Int) {
        let button = UIButton()
        button.setTitleColor(UIColor.white.withAlphaComponent(0.6), for: .highlighted)
        button.backgroundColor = .red
        let attrText = getStrokeText(
            "GO!",
            .white,
            font: MyFont.bold(ofSize: 5 * stepFloat)
        )
        button.setAttributedTitle(attrText, for: .normal)
        button.roundBorder(borderWidth: stepFloat/2,
                           cornerRadius: stepFloat * CGFloat(w)/2,
                           color: .black)
        button.showsTouchWhenHighlighted = true
        button.addTarget(self, action: #selector(onGoButtonClicked), for: .touchUpInside)

        layout(x, y, w, w, button)
        addSubview(button)
    }

    @objc func onGoButtonClicked() {
        context.gameMode = .medalMode
        guard !TopicDetailPage.isChallengeButtonDisabled else { return }
        if let vc = UIApplication.getPresentedViewController() {
            if isUnderDailySentenceLimit() {
                launchVC(vc, "MessengerGame")
            }
        }
    }

}

func rollingText(view: UIView) {
    let animator = UIViewPropertyAnimator(duration: 15, curve: .easeOut, animations: {
        view.transform = CGAffineTransform.identity
            .translatedBy(x: 0, y: screen.width/2)
            .rotated(by: -1 * .pi/8)
            .translatedBy(x: -1.5 * screen.width * cos(.pi/8), y: -1.5 * screen.width * sin(.pi/8))
    })

    animator.startAnimation()
}

extension GridLayout where Self: UIView {
    func drawTextBackground(bgColor: UIColor, textColor: UIColor) {
        backgroundColor = bgColor
        let num = Int(sqrt(pow(screen.width, 2) + pow(screen.height, 2)) / stepFloat)/8
        let level = context.gameMedal.lowLevel
        let sentences = getRandSentences(level: level, numOfSentences: num * 4)
        func randPad(_ string: String) -> String {
            var res = string
            let prefixCount = Int.random(in: 0 ... 10)
            let suffixCount = Int.random(in: 2 ... 10)
            for _ in 0 ..< prefixCount {
                res = " " + res
            }
            for _ in 0 ..< suffixCount {
                res += " "
            }
            return res
        }
        for i in 0 ..< num {
            let x = 1
            let y = i * 9
            let sentence = randPad(sentences[i]) +
                           randPad(sentences[i+num]) +
                           randPad(sentences[i + (2 * num)]) +
                           sentences[i + (3 * num)]
            let label = addText(x: x, y: y, h: 6 - level.rawValue/3, text: sentence, color: textColor)
            label.sizeToFit()
            label.centerX(frame)
            label.textAlignment = .left

            label.transform = CGAffineTransform.identity
                .translatedBy(x: 0, y: screen.width/2)
                .rotated(by: -1 * .pi/8)
            rollingText(view: label)
        }
    }

    func addMedalProgressBar(
        x: Int,
        y: Int,
        medalFrom: Int,
        medalTo: Int = -1,
        animateInDelay: TimeInterval = 0,
        duration: TimeInterval = 0,
        animateProgressDelay: TimeInterval = 0
    ) {
        let medalProgressBar = MedalProgressBar()
        layout(x, y, 34, 15, medalProgressBar)
        addSubview(medalProgressBar)
        medalProgressBar.medalCount = medalFrom
        medalProgressBar.viewWillAppear()
        if duration > 0 {
            medalProgressBar.animateIn(delay: animateInDelay, duration: duration)
        }

        // animate progress
        if medalTo >= 0 {
            Timer.scheduledTimer(withTimeInterval: animateProgressDelay, repeats: false) { _ in
                medalProgressBar.animateMedalProgress(to: medalTo)
            }
        }
    }
}
