import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: StatusStore

    var body: some View {
        Form {
            Section {
                TextField("Server", text: $store.baseURLString)
                    .textFieldStyle(.roundedBorder)

                Stepper(value: $store.refreshInterval, in: 1...60, step: 1) {
                    Text("Aktualisierung: \(Int(store.refreshInterval)) Sekunden")
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 420)
    }
}
