import SwiftUI

@main
struct QuantMonitorApp: App {
    @StateObject private var loader = DashboardLoader()
    @StateObject private var noteStore = EventNoteStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(loader)
                .environmentObject(noteStore)
                .onAppear {
                    if loader.hasBookmark {
                        loader.reload()
                    }
                }
        }
    }
}
