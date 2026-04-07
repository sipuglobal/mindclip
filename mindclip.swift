import AppKit
import Foundation
import UniformTypeIdentifiers

enum ClipError: Error, LocalizedError {
    case stdinEmpty
    case htmlEncodingFailed
    case htmlImportFailed
    case rtfExportFailed
    case pasteboardWriteFailed

    var errorDescription: String? {
        switch self {
        case .stdinEmpty:
            return "stdin 为空，没有读到 HTML 内容"
        case .htmlEncodingFailed:
            return "HTML 字符串转 UTF-8 数据失败"
        case .htmlImportFailed:
            return "NSAttributedString 从 HTML 导入失败"
        case .rtfExportFailed:
            return "NSAttributedString 导出 RTF 失败"
        case .pasteboardWriteFailed:
            return "写入剪贴板失败"
        }
    }
}

func readAllStdin() -> String {
    let data = FileHandle.standardInput.readDataToEndOfFile()
    if data.isEmpty { return "" }
    return String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
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

    if pb.setString(html, forType: .html) {
        wroteAny = true
    }

    if pb.setString(plain, forType: .string) {
        wroteAny = true
    }

    if let rtf, pb.setData(rtf, forType: .rtf) {
        wroteAny = true
    }

    if !wroteAny {
        throw ClipError.pasteboardWriteFailed
    }
}

do {
    let html = readAllStdin().trimmingCharacters(in: .whitespacesAndNewlines)
    if html.isEmpty {
        throw ClipError.stdinEmpty
    }

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
