import AppKit
import Foundation

enum ClipError: Error, LocalizedError {
    case stdinEmpty
    case htmlEncodingFailed
    case htmlImportFailed
    case rtfExportFailed
    case pasteboardWriteFailed

    var errorDescription: String? {
        switch self {
        case .stdinEmpty:           return "stdin 为空，没有读到内容"
        case .htmlEncodingFailed:   return "HTML 字符串转 UTF-8 数据失败"
        case .htmlImportFailed:     return "NSAttributedString 从 HTML 导入失败"
        case .rtfExportFailed:      return "NSAttributedString 导出 RTF 失败"
        case .pasteboardWriteFailed: return "写入剪贴板失败"
        }
    }
}

func readAllStdin() -> String {
    let data = FileHandle.standardInput.readDataToEndOfFile()
    if data.isEmpty { return "" }
    return String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
}

func escapeHTML(_ text: String) -> String {
    text
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "\"", with: "&quot;")
}

/// 预处理：去空行 + 把 `*` 列表标记统一成 `-`
/// 等价于 `grep . | tr '*' '-'`
func preprocess(_ text: String) -> String {
    text
        .components(separatedBy: "\n")
        .filter { !$0.isEmpty }
        .map { $0.replacingOccurrences(of: "*", with: "-") }
        .joined(separator: "\n")
}

/// 将 Markdown 缩进列表转为嵌套 <ul><li> HTML（不依赖 pandoc）
func markdownToHTML(_ markdown: String) -> String {
    // 解析每行：计算缩进量（tab 当 4 格）、提取文本
    var items: [(indent: Int, text: String)] = []
    for line in markdown.components(separatedBy: "\n") {
        var indent = 0
        for ch in line {
            if ch == " "      { indent += 1 }
            else if ch == "\t" { indent += 4 }
            else               { break }
        }
        let stripped = line.trimmingCharacters(in: .whitespaces)
        guard stripped.hasPrefix("- ") else { continue }
        items.append((indent: indent, text: String(stripped.dropFirst(2))))
    }

    guard !items.isEmpty else { return "" }

    var body = ""
    var indentStack: [Int] = []   // 每层对应的缩进值

    for (indent, text) in items {
        if indentStack.isEmpty || indent > indentStack.last! {
            // 进入更深一层
            body += "<ul><li>\(escapeHTML(text))"
            indentStack.append(indent)
        } else if indent == indentStack.last! {
            // 同级下一个节点
            body += "</li><li>\(escapeHTML(text))"
        } else {
            // 返回上层：逐步关闭直到找到匹配或更浅的层
            while indentStack.count > 1 && indentStack.last! > indent {
                body += "</li></ul>"
                indentStack.removeLast()
            }
            body += "</li><li>\(escapeHTML(text))"
            // 修正栈顶以防缩进不对齐（容错）
            if indentStack.last! != indent {
                indentStack[indentStack.count - 1] = indent
            }
        }
    }

    // 关闭所有剩余层
    while !indentStack.isEmpty {
        body += "</li></ul>"
        indentStack.removeLast()
    }

    return "<!DOCTYPE html><html><body>\(body)</body></html>"
}

func parseHTML(_ html: String) throws -> NSAttributedString {
    guard let data = html.data(using: .utf8) else {
        throw ClipError.htmlEncodingFailed
    }
    do {
        return try NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
    } catch {
        throw ClipError.htmlImportFailed
    }
}

func writeToPasteboard(html: String, plain: String, rtf: Data?) throws {
    let pb = NSPasteboard.general
    pb.clearContents()

    var wroteAny = false
    if pb.setString(html, forType: .html)   { wroteAny = true }
    if pb.setString(plain, forType: .string) { wroteAny = true }
    if let rtf, pb.setData(rtf, forType: .rtf) { wroteAny = true }

    if !wroteAny { throw ClipError.pasteboardWriteFailed }
}

do {
    let input = readAllStdin().trimmingCharacters(in: .whitespacesAndNewlines)
    if input.isEmpty { throw ClipError.stdinEmpty }

    let normalized = preprocess(input)
    let html = markdownToHTML(normalized)

    let attributed = try parseHTML(html)
    let plain = attributed.string

    let fullRange = NSRange(location: 0, length: attributed.length)
    let rtf = try? attributed.data(
        from: fullRange,
        documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
    )

    try writeToPasteboard(html: html, plain: plain, rtf: rtf)

    fputs("ok: HTML/plain text\(rtf != nil ? "/RTF" : "") 已写入剪贴板\n", stderr)
} catch {
    fputs("error: \(error.localizedDescription)\n", stderr)
    exit(1)
}
