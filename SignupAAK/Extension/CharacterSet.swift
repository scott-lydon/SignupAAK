//
//  CharacterSet.swift
//  SignupAAK
//
//  Created by Scott Lydon on 1/8/26.
//

import Foundation

extension CharacterSet {

    static var allowedCharacters: CharacterSet {
        var set: CharacterSet = CharacterSet.letters
        set.insert(charactersIn: " -'")
        return set
    }
}
