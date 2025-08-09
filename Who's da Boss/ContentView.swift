//
//  ContentView.swift
//  Who's da Boss
//
//  Created by Nyi Htet on 8/8/25.
//
import SwiftUI
import FirebaseCore

struct ContentView: View {
    init() {
        FirebaseApp.configure()
    }
    var body: some View {
        WelcomeView()
    }
}

#Preview {
    ContentView()
}
