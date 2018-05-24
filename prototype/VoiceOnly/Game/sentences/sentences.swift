enum Level: Int {
    case n5, n4, n3
}

var allSentences: [String: [String]] = [:]
var allSentencesKeys: [String] = []
var allLevels: [String: Level] = [:]

let n5Prefix = "N5 口說"
let n4Prefix = "N4 口說"
let n3Prefix = "N3 口說"

func addSentences(sentences: [String], prefix: String, level: Level) {
    let sectionNum = 25
    var index = 0
    var serial = 1
    repeat {
        let subSentences = Array(sentences[index..<index+sectionNum])
        let key = "\(prefix) \(serial)"
        allSentences[key] = subSentences
        allSentencesKeys.append(key)
        allLevels[key] = level
        index += sectionNum
        serial += 1
    } while (index + sectionNum) <= sentences.count
}
