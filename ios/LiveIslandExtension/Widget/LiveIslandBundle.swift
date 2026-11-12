import SwiftUI
import WidgetKit

@main
struct LiveIslandBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.1, *) {
            LiveIslandWidget()
        }
    }
}
