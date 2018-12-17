//
//  MessengerEventDelegate.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on H30/05/11.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//

import Foundation
import UIKit

private let context = GameContext.shared
private let i18n = I18n.shared
private var tmpRangeQueue: [NSRange] = []

extension Messenger: GameEventDelegate {
    @objc func onEventHappened(_ notification: Notification) {
        guard let event = notification.object as? Event else { print("convert event fail"); return }

        switch event.type {
        case .sayStarted:
            guard let text = event.string else { return }
            if context.gameState == .justStarted {
                addLabel(rubyAttrStr(text))
            }

        case .willSpeakRange:
            guard let newRange = event.range else { return }
            if !context.gameSetting.isShowTranslation,
               context.gameState == .TTSSpeaking {
                tmpRangeQueue.append(newRange)
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                    if !tmpRangeQueue.isEmpty {
                        tmpRangeQueue.removeFirst()
                    }
                }
                let allRange: NSRange = tmpRangeQueue.reduce(tmpRangeQueue[0], {allR, curR in
                    return allR.union(curR)
                })

                var attrText = NSMutableAttributedString()
                if let tokenInfos = kanaTokenInfosCacheDictionary[context.targetString] {
                    attrText = getFuriganaString(tokenInfos: tokenInfos, highlightRange: allRange)
                } else {
                    attrText.append(rubyAttrStr(context.targetString))
                    attrText.addAttribute(.backgroundColor, value: myOrange.withAlphaComponent(0.6), range: allRange)
                    var whiteRange = NSRange(location: allRange.upperBound, length: context.targetString.count - allRange.upperBound)
                    attrText.addAttribute(.backgroundColor, value: UIColor.clear, range: whiteRange)

                }
                lastLabel.attributedText = attrText
            }

        case .speakEnded:
            if !context.gameSetting.isShowTranslation,
                context.gameState == .TTSSpeaking {
                lastLabel.attributedText = context.targetAttrString
            }
        case .listenStarted:
            addLabel(rubyAttrStr("..."), pos: .right)

        case .scoreCalculated:
            DispatchQueue.main.async {
                self.levelMeterValueBar.frame.size.height = 0
            }
            guard let score = event.score else { return }
            onScore(score)

        case .lifeChanged:
            speedLabel.text = String(format: "%.2f 倍速", context.teachingRate * 2)

        case .playTimeUpdate:
            guard let seconds = event.int else { return }
            func add0(_ s: String) -> String {
                return s.count == 1 ? "0" + s : s
            }

            timeLabel.text = "\(add0((seconds/60).s)):\(add0((seconds%60).s))"
            speedLabel.text = String(format: "%.2f 倍速", context.teachingRate * 2)

        case .levelMeterUpdate:
            guard let micLevel = event.int else { return }
            DispatchQueue.main.async {
                let height = CGFloat(20.0 * micLevel.f / 100.0)
                self.levelMeterValueBar.frame.size.height = height
                self.levelMeterValueBar.frame.origin.y = 6 + 20 - height
            }

        case .gameStateChanged:
            if context.gameState == .gameOver {
                stopEventObserving(self)
                addLabel(rubyAttrStr("遊戲結束。"))

                // prevent alerting block present
                isAlerting.always {
                    launchStoryboard(self, "GameFinishedPage", isOverCurrent: true, animated: true)
                }
            }

            if context.gameState == .TTSSpeaking {
                tmpRangeQueue = []
                let text = context.targetString
                var translationsDict = (gameLang == .jp && context.contentTab == .topics) ?
                    chTranslations : translations
                var attrText: NSAttributedString
                if context.gameSetting.isShowTranslation,
                    let translation = translationsDict[text] {
                    attrText = rubyAttrStr(translation)
                } else {
                    attrText = context.targetAttrString
                }
                prescrolling(attrText)
                addLabel(attrText)
            }

            if context.gameState == .forceStopped {
                dismiss(animated: false)
            }

            if context.gameState == .echoMethod {
                addLabel(rubyAttrStr(i18n.listenToEcho), pos: .center)
            }
        }
    }

    private func onScore(_ score: Score) {
        let attributed = NSMutableAttributedString()
        if let tokenInfos = kanaTokenInfosCacheDictionary[context.userSaidString],
           gameLang == .jp {
            attributed.append(getFuriganaString(tokenInfos: tokenInfos))
        } else {
            attributed.append(rubyAttrStr(context.userSaidString))
        }

        print(context.userSaidString)

        if attributed.string == "" {
            attributed.append(rubyAttrStr(i18n.iCannotHearYou))
        }

        attributed.append(rubyAttrStr(" \(score.valueText) \(score.type == .perfect ? "💯": "")"))

        updateLastLabelText(attributed, pos: .right)

        lastLabel.backgroundColor = score.color
        sentenceCountLabel.text = "\(i18n.remaining)\(context.sentences.count - context.sentenceIndex - 1)\(i18n.sentenceUnit)"
    }
}
