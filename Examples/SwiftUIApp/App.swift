import Aptabase
import SwiftUI

@main
struct HelloWorldApp: App {
    var body: some Scene {
        WindowGroup {
            CounterView()
        }
    }
}

import Aptabase
import SwiftUI

struct CounterView: View {
    @State var count: Int = 0

    var body: some View {
        VStack {
            Text("Count = \(count)")
            Button(action: {
                count += 1
                Metrics.shared.track("Increment", ["count": count])
            }) {
                Text("Increment")
            }.padding()
        }
    }
}

struct CounterView_Previews: PreviewProvider {
    static var previews: some View {
        CounterView()
    }
}
