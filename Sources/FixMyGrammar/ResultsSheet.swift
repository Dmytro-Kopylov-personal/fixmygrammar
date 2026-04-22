import AppKit
import SwiftUI

struct ResultsSheet: View {
    let result: GrammarRunResult
    var onDismiss: () -> Void
    @EnvironmentObject private var appModel: AppModel

    private var showFullReport: Bool { appModel.showFullReportInResults }

    private var hasIssues: Bool {
        guard let p = result.parsed else { return false }
        return !p.issues.isEmpty
    }

    private var isUnparsed: Bool { result.parsed == nil }

    private var showReportCard: Bool {
        showFullReport && (hasIssues || isUnparsed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Grammar check")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("Done", action: onDismiss)
                    .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if result.inputWasTruncated, let note = result.truncationNote {
                        Text(note)
                            .font(.callout)
                            .foregroundStyle(.primary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.yellow.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
                    }

                    textPanel

                    if showReportCard {
                        reportPanel
                    } else if isUnparsed && !showFullReport {
                        Text("The model did not return valid JSON. Turn on “Show full report” in Settings to inspect the raw response.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()

            Divider()

            HStack {
                Button("Copy corrected") {
                    let text = result.parsed?.correctedText ?? result.rawResponse
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                    onDismiss()
                }
                .disabled(result.parsed == nil && result.rawResponse.isEmpty)

                if showFullReport {
                    Button("Copy full report") {
                        var lines: [String] = ["## Original", result.sourceText, "", "## Model output", result.rawResponse]
                        if let p = result.parsed {
                            lines.append("")
                            lines.append("## Corrected")
                            lines.append(p.correctedText)
                            if !p.issues.isEmpty {
                                lines.append("")
                                lines.append("## Issues")
                                for i in p.issues {
                                    lines.append("- \(i.title): \(i.detail)")
                                }
                            }
                        }
                        let blob = lines.joined(separator: "\n")
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(blob, forType: .string)
                        onDismiss()
                    }
                }

                Spacer()
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var textPanel: some View {
        panelChrome(title: "Your text", subtitle: "Original and corrected passage") {
            VStack(alignment: .leading, spacing: 16) {
                labeledBlock(title: "Original") {
                    Text(result.sourceText)
                        .textSelection(.enabled)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if let parsed = result.parsed {
                    Divider()
                    labeledBlock(title: "Corrected") {
                        Text(parsed.correctedText)
                            .textSelection(.enabled)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else if !showFullReport {
                    Divider()
                    labeledBlock(title: "Model output") {
                        Text(result.rawResponse)
                            .textSelection(.enabled)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private var reportPanel: some View {
        panelChrome(title: "Report", subtitle: "Issues and raw model output") {
            VStack(alignment: .leading, spacing: 16) {
                if let parsed = result.parsed, !parsed.issues.isEmpty {
                    labeledBlock(title: "Issues") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(parsed.issues.enumerated()), id: \.offset) { _, issue in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(issue.title)
                                            .font(.headline)
                                        if let sev = issue.severity, !sev.isEmpty {
                                            Text(sev)
                                                .font(.caption)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(.quaternary, in: Capsule())
                                        }
                                    }
                                    Text(issue.detail)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }

                if isUnparsed {
                    if hasIssues { Divider() }
                    labeledBlock(title: "Model output (unparsed)") {
                        Text(result.rawResponse)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }

    private func panelChrome(title: String, subtitle: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.background.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.separator.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }

    private func labeledBlock(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
