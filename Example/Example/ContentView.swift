//
//  ContentView.swift
//  Example
//
//  Created by xaoxuu on 2022/4/22.
//

import SwiftUI
import AppCrashTracer

// 扩展自己项目的业务模块
extension AppCrashRecorder.Session {
    static var live: Self { .init("live") }
}

struct ContentView: View {
    
    @State private var isSharePresented: Bool = false

    var body: some View {
        VStack(spacing: 32.0) {
            Text("App Crash Tracer")
                .font(.title2)
                .fontWeight(.heavy)
                .padding()
            VStack {
                Button("Record Event 123") {
                    AppCrashRecorder.record(.app)
                }
                Button("Record Event 456") {
                    AppCrashRecorder.record(.live, "event 456")
                }
            }
            VStack {
                Button("💥 Crash 💥") {
                    let x = [0]
                    print(x[1])
                }
            }
            .tint(.red)
            VStack {
                Button("Export Crash Log Files") {
                    self.isSharePresented = true
                }
                .buttonStyle(.borderedProminent)
                .sheet(isPresented: $isSharePresented, onDismiss: {
                    print("Dismiss")
                }, content: {
                    let urls = AppCrashRecorder.exportLogFiles()
                    ActivityViewController(activityItems: urls)
                })
                Button("Print Crash Json") {
                    let objs = AppCrashRecorder.exportLogObjects()
                    print(objs)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .buttonStyle(.bordered)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct ActivityViewController: UIViewControllerRepresentable {

    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}

}
