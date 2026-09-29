import AppKit

// 生成 1024x1024 应用图标：黑底 + 白色英文花体字（Task / Calendar 同字号、上下布局）
let S: CGFloat = 1024
let img = NSImage(size: NSSize(width: S, height: S))
img.lockFocus()

let outer = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: S, height: S),
                         xRadius: S * 0.2237, yRadius: S * 0.2237)
outer.addClip()

// 纯黑背景
NSColor(calibratedRed: 0.04, green: 0.04, blue: 0.05, alpha: 1).setFill()
outer.fill()

// 选取系统花体字体（Snell Roundhand / Savoye / Zapfino 之一）
func pickScriptFont(size: CGFloat) -> NSFont {
    let postscriptCandidates = ["SnellRoundhand-Bold", "SnellRoundhand", "Zapfino", "SavoyeLetPlain"]
    for name in postscriptCandidates {
        if let f = NSFont(name: name, size: size) { return f }
    }
    // 兜底：按族名枚举匹配
    let fm = NSFontManager.shared
    let hitFamilies = fm.availableFontFamilies.filter {
        let u = $0.lowercased()
        return u.contains("snell") || u.contains("savoye") || u.contains("zapfino")
            || u.contains("script") || u.contains("hand")
    }
    for fam in hitFamilies {
        if let m = fm.availableMembers(ofFontFamily: fam), let first = m.first,
           let ps = first[0] as? String, let f = NSFont(name: ps, size: size) {
            return f
        }
    }
    return NSFont.systemFont(ofSize: size, weight: .bold)
}

let F: CGFloat = 230          // 两个单词字号一致
let font = pickScriptFont(size: F)

func drawCentered(_ text: String, baselineY: CGFloat) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
    ]
    let s = NSAttributedString(string: text, attributes: attrs)
    let sz = s.size()
    s.draw(at: NSPoint(x: (S - sz.width) / 2, y: baselineY))
}

// 上下布局：Task 在上、Calendar 在下，整体垂直居中（基线按花体字形实测偏移）
drawCentered("Task", baselineY: S * 0.44)
drawCentered("Calendar", baselineY: S * 0.24)

img.unlockFocus()

let rep = NSBitmapImageRep(data: img.tiffRepresentation!)!
let data = rep.representation(using: .png, properties: [:])!
try! data.write(to: URL(fileURLWithPath: "/tmp/AppIconMaster.png"))
print("icon written: /tmp/AppIconMaster.png font=\(font.fontName)")
