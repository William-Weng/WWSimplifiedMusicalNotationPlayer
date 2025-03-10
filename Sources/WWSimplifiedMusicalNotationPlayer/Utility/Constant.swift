//
//  Constant.swift
//  WWSimplifiedMusicalNotationPlayer
//
//  Created by William.Weng on 2025/3/10.
//

import UIKit

extension WWSimplifiedMusicalNotationPlayer {
    
    typealias NoteInformation = (note: String, frequency: CGFloat, duration: Double)    // (音符, 頻率, 持續時間)
}

extension WWSimplifiedMusicalNotationPlayer {
    
    enum NotationError: Error {
        
        case noteNotInTable
        case audioFormat
        case audioPCMBuffer
        case playNote(_ note: String)
        
        func message() -> String {
            switch self {
            case .noteNotInTable: return "This note is not in the table."
            case .audioFormat: return "AudioFormat error."
            case .audioPCMBuffer: return "AudioPCMBuffer error."
            case .playNote(let note): return "Play \(note) error."
            }
        }
    }
}
