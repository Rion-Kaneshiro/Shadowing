//
//  Furigana.swift
//  VoiceOnly
//
//  Created by Wangchou Lu on H30/05/17.
//  Copyright © 平成30年 Lu, WangChou. All rights reserved.
//
// modified from
// https://stackoverflow.com/questions/46690337/swift-4-ctrubyannotation-dont-work

import Foundation
import Promises

#if os(iOS)
    import UIKit

    // fonts
    // .HiraKakuInterface-W2
    // HiraKakuProN-W3
    // HiraginoSans-W3
    // HiraMinProN-W6
    let rubyAnnotationKey = kCTRubyAnnotationAttributeName as NSAttributedString.Key
    func rubyAttrStr(
        _ string: String,
        _ ruby: String = "",
        fontSize: CGFloat = 20,
        color: UIColor = .black,
        isWithStroke: Bool = false,
        backgroundColor: UIColor = .clear
    ) -> NSAttributedString {
        let fontRegular = MyFont.regular(ofSize: fontSize)
        let fontBold = MyFont.bold(ofSize: fontSize)
        let isSimple = color == .black || !isWithStroke

        var attributes: [NSAttributedString.Key: Any] = [
            .font: isSimple ? fontRegular : fontBold,
            .hightlightBackgroundFillColor: UIColor.clear,
            //.nantesLabelBackgroundCornerRadius: 5,
        ]

        if color != .black {
            attributes[.foregroundColor] = color
        }

        if !isSimple {
            attributes[.strokeColor] = UIColor.black
            attributes[.strokeWidth] = -1.5
        }

        if ruby != "" {
            let fontRuby = MyFont.rubyThin(ofSize: fontSize / 2)
            let alignMode: CTRubyAlignment = ruby.count >= string.count * 2 ? .center : .auto
            var rubyAttributes: CFDictionary
            if #available(iOS 13, *) {
                rubyAttributes = [kCTFontAttributeName: fontRuby,
                 kCTStrokeWidthAttributeName: -2.0,
                ] as CFDictionary
            } else {
                rubyAttributes = [kCTFontAttributeName: fontRuby,
                ] as CFDictionary
            }
            let annotation = CTRubyAnnotationCreateWithAttributes(
                alignMode, .auto, .before, ruby as CFString,
                rubyAttributes
            )
            attributes[rubyAnnotationKey] = annotation
        }

        return NSAttributedString(
            string: string,
            attributes: attributes
        )
    }

//    case 1:
//    parts: [わたし、| 気 | になります！]
//    kana: わたしきになります
//
//    case2:
//    parts: [逃 | げるは | 恥 | だが | 役 | に | 立 | つ]
//    kana: にげるははじだがやくにたつ
//    case3:
//    parts: [ブラック | 企業勤 | めのころ]
//    kana: ...
//    case4:
//    parts: [男 | の | 子女 | の | 子]
//    kana: おとこのこおんなのこ
    func getFuriganaAttrString(_ parts: [String],
                               _ kana: String,
                               color: UIColor = .black,
                               highlightRange: NSRange? = nil) -> NSMutableAttributedString {
        var currentIndex = 0
        func isInRange() -> Bool {
            guard let r = highlightRange else { return false }
            return r.contains(currentIndex)
        }
        func getBackgroundColor() -> UIColor {
            return isInRange() ? highlightColor : .clear
        }

        let attrStr = NSMutableAttributedString()

        if parts.isEmpty { return attrStr }

        if parts.count == 1 {
            let backgroundColor = getBackgroundColor()
            let result = parts[0].jpnType == JpnType.noKanjiAndNumber ?
                rubyAttrStr(parts[0], color: color, isWithStroke: color != .black, backgroundColor: backgroundColor) :
                rubyAttrStr(parts[0], kana, color: color, isWithStroke: color != .black, backgroundColor: backgroundColor)

            attrStr.append(result)
            return attrStr
        }

        // divider is first non "kanji or number part" in parts
        for dividerIndex in 0 ..< parts.count {
            let divider = parts[dividerIndex]
            guard divider.jpnType == JpnType.noKanjiAndNumber,
                kana.patternCount(divider.hiraganaOnly) == (parts.filter { $0.hiraganaOnly == divider.hiraganaOnly }).count
            else {
                continue
            }

            guard let range = kana.range(of: divider.hiraganaOnly) else { continue }

            // before divider part
            if dividerIndex > 0 {
                attrStr.append(getFuriganaAttrString(
                    parts[..<dividerIndex].a,
                    kana[..<range.lowerBound].s,
                    color: color,
                    highlightRange: highlightRange?.subRange(startIndex: currentIndex)
                ))
                currentIndex += parts[..<dividerIndex].a.reduce(0) { result, part in
                    result + part.count
                }
            }

            // divider
            attrStr.append(rubyAttrStr(divider, color: color, isWithStroke: color != .black, backgroundColor: getBackgroundColor()))
            currentIndex += parts[dividerIndex].count

            // after divider part
            if dividerIndex + 1 < parts.count {
                attrStr.append(getFuriganaAttrString(
                    parts[(dividerIndex + 1)...].a,
                    kana[range.upperBound...].s,
                    color: color,
                    highlightRange: highlightRange?.subRange(startIndex: currentIndex)
                ))
            }

            return attrStr
        }

        attrStr.append(rubyAttrStr(parts.joined(), kana, color: color))
        return attrStr
    }

    extension NSRange {
        // subRange from startIndex of old string
        func subRange(startIndex: Int) -> NSRange? {
            guard startIndex < upperBound else { return nil }

            return NSRange(
                location: max(lowerBound - startIndex, 0),
                length: upperBound - startIndex
            )
        }
    }

    // tokenInfo = [kanji, 詞性, furikana, yomikana]
    func getFuriganaString(tokenInfos: [[String]], highlightRange: NSRange? = nil) -> NSMutableAttributedString {
        let furiganaAttrStr = NSMutableAttributedString()
        var currentIndex = 0
        func isInRange() -> Bool {
            guard let r = highlightRange else { return false }
            return r.contains(currentIndex)
        }

        for tokenInfo in tokenInfos {
            if tokenInfo.last == "*" { // number strings, ex: “307”号室
                furiganaAttrStr.append(rubyAttrStr(tokenInfo[0], backgroundColor: isInRange() ? highlightColor : .clear))
            } else if tokenInfo[1] == "記号" {
                furiganaAttrStr.append(rubyAttrStr(tokenInfo[0], backgroundColor: .clear))
            } else {
                let kanjiStr = tokenInfo[0]
                let kana = getFixedFuriganaForScore(kanjiStr) ?? tokenInfo[tokenInfo.count - 2].kataganaToHiragana
                let parts = kanjiStr // [わたし、| 気 | になります！]
                    .replaceRegex("([\\p{Han}\\d]*[\\p{Han}\\d])", "👻$1👻")
                    .components(separatedBy: "👻")
                    .filter { $0 != "" }

                let color: UIColor = (tokenInfo[1] == "助詞" && kana.isImportantParticle)
                    ? myWaterBlue : .black

                var subHighlightRange = highlightRange?.subRange(startIndex: currentIndex)

                // "動詞" is not dividable, ex: "降り"そう, bgColor of "降" & "り" should be the same
                if tokenInfo[1] == "動詞" || tokenInfo[1] == "形容詞",
                    isInRange() {
                    subHighlightRange = kanjiStr.fullRange
                }

                furiganaAttrStr.append(getFuriganaAttrString(
                    parts,
                    kana,
                    color: color,
                    highlightRange: subHighlightRange
                ))
            }
            currentIndex += tokenInfo[0].count
        }

        return furiganaAttrStr
    }

#else
    // OSX code
#endif
