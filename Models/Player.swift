//
//  Player.swift
//  Who's da Boss
//
//  Created by Nyi Htet on 8/12/25.
//

struct Player: Identifiable, Hashable {
    let id: String
    let name: String
    let funFact: String
    let avatarURL: String?
}

struct funFact: Identifiable {
    let id: String
    let fact: String
    let options: [Player]
    let correctPlayerID: String 
}
