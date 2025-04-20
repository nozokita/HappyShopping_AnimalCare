//
//  HappyShoppingApp.swift
//  HappyShopping
//
//  Created by Nozomu Kitamura on 4/20/25.
//

import SwiftUI

@main
struct HappyShoppingApp: App {
    @StateObject private var gameViewModel = GameViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
 