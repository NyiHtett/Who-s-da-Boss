//
//  ContentView.swift
//  Who's da Boss
//
//  Created by Nyi Htet on 8/8/25.
//
import SwiftUI
import FirebaseCore
import FirebaseStorage

struct ContentView: View {
    init() {
        FirebaseApp.configure()
        
        // create the bucket
        let bucket = "gs://who-s-da-boss-7f05a.firebasestorage.app"
        // create a storage pointed at the bucket
        _ = Storage.storage(url: bucket)
    }
    var body: some View {
        WelcomeView()
    }
}

#Preview {
    ContentView()
}
