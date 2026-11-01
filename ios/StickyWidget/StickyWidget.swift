import SwiftUI
import WidgetKit

/// Home-screen widget for iOS. Shows a picture of the board when the app has
/// exported one to it and "Board picture" is chosen, else a board's pinned or
/// newest notes as text, in the colours and text size chosen in the app —
/// the same data the Android widget reads, written by the home_widget plugin
/// into the shared app group (see lib/services/widget_service.dart).
///
/// Adding the extension target to the Xcode project is a one-time manual
/// step; see README → "iOS widget".
let appGroup = "group.com.winka.stickyWall"

struct BoardEntry: TimelineEntry {
  let date: Date
  let title: String
  let lines: [String]
  let empty: String
  let look: String
  let textSize: String
  let wallImage: UIImage?
}

struct BoardProvider: TimelineProvider {
  func placeholder(in context: Context) -> BoardEntry {
    BoardEntry(
      date: Date(), title: "Sticky Wall", lines: ["…"], empty: "",
      look: "wall", textSize: "normal", wallImage: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (BoardEntry) -> Void) {
    completion(read())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<BoardEntry>) -> Void) {
    // The app pushes an update whenever something changes; refresh on our own
    // every half hour in case that was missed.
    let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
    completion(Timeline(entries: [read()], policy: .after(next)))
  }

  private func read() -> BoardEntry {
    let defaults = UserDefaults(suiteName: appGroup)
    let title = defaults?.string(forKey: "title") ?? "Sticky Wall"
    let lines = (1...6).compactMap { defaults?.string(forKey: "line\($0)") }
      .filter { !$0.isEmpty }
    // Before the app wrote a mode, a sent picture was always shown.
    let mode = defaults?.string(forKey: "mode")
    var image: UIImage? = nil
    if mode == nil || mode == "picture",
      let path = defaults?.string(forKey: "wall"), FileManager.default.fileExists(atPath: path)
    {
      image = downscaled(UIImage(contentsOfFile: path), maxEdge: 900)
    }
    return BoardEntry(
      date: Date(), title: title, lines: lines,
      empty: defaults?.string(forKey: "empty") ?? "No pinned notes",
      look: defaults?.string(forKey: "look") ?? "wall",
      textSize: defaults?.string(forKey: "textSize") ?? "normal",
      wallImage: image)
  }

  /// WidgetKit caps the memory a widget may use; the export is a 3× render,
  /// far more than a widget needs.
  private func downscaled(_ image: UIImage?, maxEdge: CGFloat) -> UIImage? {
    guard let image = image else { return nil }
    let longest = max(image.size.width, image.size.height)
    if longest <= maxEdge { return image }
    let scale = maxEdge / longest
    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
  }
}

struct StickyWidgetView: View {
  let entry: BoardEntry

  // Matches widgetColors in lib/widgets/widget_settings_sheet.dart.
  private var background: Color {
    switch entry.look {
    case "paper": return Color(red: 0xFF / 255, green: 0xF9 / 255, blue: 0xE6 / 255)
    case "ink": return Color(red: 0x2B / 255, green: 0x2A / 255, blue: 0x25 / 255)
    default: return Color(red: 0x6B / 255, green: 0x58 / 255, blue: 0x49 / 255)
    }
  }
  private var ink: Color {
    entry.look == "paper"
      ? Color(red: 0x3B / 255, green: 0x37 / 255, blue: 0x2F / 255)
      : Color(red: 0xFD / 255, green: 0xFB / 255, blue: 0xF3 / 255)
  }
  private var titleSize: CGFloat {
    entry.textSize == "small" ? 14 : entry.textSize == "large" ? 19 : 16
  }
  private var lineSize: CGFloat {
    entry.textSize == "small" ? 12 : entry.textSize == "large" ? 17 : 14
  }

  var body: some View {
    ZStack {
      background
      if let image = entry.wallImage {
        Image(uiImage: image)
          .resizable()
          .aspectRatio(contentMode: .fill)
      } else {
        VStack(alignment: .leading, spacing: 6) {
          Text(entry.title)
            .font(.system(size: titleSize, weight: .bold))
            .foregroundColor(ink)
            .lineLimit(1)
          if entry.lines.isEmpty {
            Text(entry.empty)
              .font(.system(size: lineSize))
              .foregroundColor(ink.opacity(0.8))
          } else {
            ForEach(entry.lines, id: \.self) { line in
              Text("• \(line)")
                .font(.system(size: lineSize))
                .foregroundColor(ink)
                .lineLimit(1)
            }
          }
          Spacer(minLength: 0)
        }
        .padding(14)
      }
    }
    .widgetBackground(background)
  }
}

extension View {
  /// iOS 17 asks widgets to declare their background; older systems draw it
  /// themselves.
  @ViewBuilder
  func widgetBackground(_ color: Color) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { color }
    } else {
      background(color)
    }
  }
}

@main
struct StickyWidget: Widget {
  let kind = "StickyWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: BoardProvider()) { entry in
      StickyWidgetView(entry: entry)
    }
    .configurationDisplayName("Sticky Wall")
    .description("Your board, or its pinned notes, on the home screen.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}
