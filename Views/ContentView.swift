//
//  ContentView.swift
//  Shared
//
//  Created by TiankaiMa on 2022/12/14.
//

import SwiftUI
import SwiftyJSON


// main entry point, edit this when we need documentGroup or something like that...
// keep it unchanged before an iPad version is planned, which I have no idea how to implment that, especially UI
@main
struct Life_USTCApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    // these four variables are used to deterime which sheet is required tp prompot to the user.
#if DEBUG
    @State var casLoginSheet: Bool = false
    @State var firstLogin: Bool = false
#else
    @State var casLoginSheet: Bool = false
    @AppStorage("firstLogin") var firstLogin: Bool = true
#endif
    
    @AppStorage("passportUsername") var passportUsername: String = ""
    @AppStorage("passportPassword") var passportPassword: String = ""
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "square.stack.3d.up")
                }
            FeaturesView()
                .tabItem {
                    Label("Features", systemImage: "square.grid.2x2.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .sheet(isPresented: $firstLogin) {
            UserTypeView(userTypeSheet: $firstLogin)
                .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $casLoginSheet) {
            CASLoginView(casLoginSheet: $casLoginSheet, isInSheet: true, title: "One more step...", displayMode: .large)
                .interactiveDismissDisabled(true)
        }
        .onAppear(perform: onLoadFunction)
    }
    
    func onLoadFunction() {
        do {
            try loadPostCache()
            loadMainUser()
        } catch {
            print(error)
        }
    }
}