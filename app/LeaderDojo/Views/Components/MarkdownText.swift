import SwiftUI

/// A view that renders markdown content with proper formatting
struct MarkdownText: View {
    let content: String
    let baseFont: Font
    
    init(_ content: String, font: Font = .body) {
        self.content = content
        self.baseFont = font
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                renderBlock(block)
            }
        }
    }
    
    // MARK: - Block Types
    
    private enum MarkdownBlock: Equatable {
        case heading(level: Int, text: String)
        case paragraph(text: String)
        case bulletList(items: [String])
        case numberedList(items: [String])
        case codeBlock(code: String)
        case blockquote(text: String)
        case horizontalRule
    }
    
    // MARK: - Parsing
    
    private func parseBlocks() -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = content.components(separatedBy: .newlines)
        var currentParagraph: [String] = []
        var currentList: [String] = []
        var currentListType: String? = nil // "bullet" or "numbered"
        var inCodeBlock = false
        var codeBlockContent: [String] = []
        
        func flushParagraph() {
            if !currentParagraph.isEmpty {
                let text = currentParagraph.joined(separator: " ").trimmingCharacters(in: .whitespaces)
                if !text.isEmpty {
                    blocks.append(.paragraph(text: text))
                }
                currentParagraph = []
            }
        }
        
        func flushList() {
            if !currentList.isEmpty {
                if currentListType == "bullet" {
                    blocks.append(.bulletList(items: currentList))
                } else if currentListType == "numbered" {
                    blocks.append(.numberedList(items: currentList))
                }
                currentList = []
                currentListType = nil
            }
        }
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Code block handling
            if trimmed.hasPrefix("```") {
                if inCodeBlock {
                    // End code block
                    blocks.append(.codeBlock(code: codeBlockContent.joined(separator: "\n")))
                    codeBlockContent = []
                    inCodeBlock = false
                } else {
                    // Start code block
                    flushParagraph()
                    flushList()
                    inCodeBlock = true
                }
                continue
            }
            
            if inCodeBlock {
                codeBlockContent.append(line)
                continue
            }
            
            // Empty line - end current paragraph
            if trimmed.isEmpty {
                flushParagraph()
                flushList()
                continue
            }
            
            // Horizontal rule
            if trimmed.allSatisfy({ $0 == "-" || $0 == "*" || $0 == "_" }) && trimmed.count >= 3 {
                flushParagraph()
                flushList()
                blocks.append(.horizontalRule)
                continue
            }
            
            // Headings
            if let headingMatch = parseHeading(trimmed) {
                flushParagraph()
                flushList()
                blocks.append(.heading(level: headingMatch.level, text: headingMatch.text))
                continue
            }
            
            // Blockquote
            if trimmed.hasPrefix(">") {
                flushParagraph()
                flushList()
                let quoteText = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                blocks.append(.blockquote(text: quoteText))
                continue
            }
            
            // Bullet list
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("• ") {
                flushParagraph()
                if currentListType != "bullet" {
                    flushList()
                    currentListType = "bullet"
                }
                let itemText = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                currentList.append(itemText)
                continue
            }
            
            // Numbered list
            if let numberedItem = parseNumberedListItem(trimmed) {
                flushParagraph()
                if currentListType != "numbered" {
                    flushList()
                    currentListType = "numbered"
                }
                currentList.append(numberedItem)
                continue
            }
            
            // Regular paragraph line
            flushList()
            currentParagraph.append(trimmed)
        }
        
        // Flush remaining content
        if inCodeBlock {
            blocks.append(.codeBlock(code: codeBlockContent.joined(separator: "\n")))
        }
        flushParagraph()
        flushList()
        
        return blocks
    }
    
    private func parseHeading(_ line: String) -> (level: Int, text: String)? {
        var level = 0
        var remaining = line[...]
        
        while remaining.hasPrefix("#") && level < 6 {
            level += 1
            remaining = remaining.dropFirst()
        }
        
        guard level > 0, remaining.hasPrefix(" ") else {
            return nil
        }
        
        let text = String(remaining).trimmingCharacters(in: .whitespaces)
        return (level, text)
    }
    
    private func parseNumberedListItem(_ line: String) -> String? {
        let pattern = #"^(\d+)\.\s+(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let textRange = Range(match.range(at: 2), in: line) else {
            return nil
        }
        return String(line[textRange])
    }
    
    // MARK: - Rendering
    
    @ViewBuilder
    private func renderBlock(_ block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            renderHeading(level: level, text: text)
            
        case .paragraph(let text):
            renderInlineMarkdown(text)
                .font(baseFont)
            
        case .bulletList(let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        renderInlineMarkdown(item)
                            .font(baseFont)
                    }
                }
            }
            
        case .numberedList(let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 20, alignment: .trailing)
                        renderInlineMarkdown(item)
                            .font(baseFont)
                    }
                }
            }
            
        case .codeBlock(let code):
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.callout, design: .monospaced))
                    .padding(12)
            }
            .background(Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            
        case .blockquote(let text):
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.accentColor.opacity(0.5))
                    .frame(width: 3)
                renderInlineMarkdown(text)
                    .font(baseFont)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            
        case .horizontalRule:
            Divider()
                .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private func renderHeading(level: Int, text: String) -> some View {
        let font: Font = {
            switch level {
            case 1: return .title
            case 2: return .title2
            case 3: return .title3
            case 4: return .headline
            default: return .subheadline
            }
        }()
        
        renderInlineMarkdown(text)
            .font(font)
            .fontWeight(.semibold)
            .padding(.top, level <= 2 ? 8 : 4)
    }
    
    /// Renders inline markdown (bold, italic, code, links) using SwiftUI's AttributedString
    @ViewBuilder
    private func renderInlineMarkdown(_ text: String) -> some View {
        if let attributed = try? AttributedString(markdown: text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attributed)
        } else {
            Text(text)
        }
    }
}

// MARK: - Preview

#Preview("Markdown Examples") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            MarkdownText("""
            # Heading 1
            ## Heading 2
            ### Heading 3
            
            This is a **bold** and *italic* text example with `inline code`.
            
            - First bullet point
            - Second bullet point
            - Third bullet point
            
            1. First numbered item
            2. Second numbered item
            3. Third numbered item
            
            > This is a blockquote that might contain important information.
            
            ```
            func hello() {
                print("Hello, World!")
            }
            ```
            
            ---
            
            Here's a [link](https://example.com) in the text.
            """)
        }
        .padding()
    }
}

