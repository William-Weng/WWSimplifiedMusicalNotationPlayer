//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2025/3/10.
//

import UIKit
import WWSimplifiedMusicalNotationPlayer

// MARK: - ViewController
final class ViewController: UIViewController {
    
    @IBOutlet var notes: [UIView]!
    
    private let player = WWSimplifiedMusicalNotationPlayer()
    private let notation = "1 1 5 5 6 6 5 0 4 4 3 3 2 2 1 0 5 5 4 4 3 3 2 0 5 5 4 4 3 3 2 0 1 1 5 5 6 6 5 0 4 4 3 3 2 2 1-"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetting()
    }
    
    @IBAction func playDemo(_ sender: UIBarButtonItem) {
        player.playSong(notation)
    }
}

private extension ViewController {
    
    func initSetting() {
        
        notes.forEach {
            let tap = UITapGestureRecognizer(target: self, action: #selector(playNote))
            $0.isUserInteractionEnabled = true
            $0.addGestureRecognizer(tap)
        }
    }
    
    @objc func playNote(_ tap: UITapGestureRecognizer) {
        guard let note = tap.view?.tag else { return }
        _ = player.playNote("\(note)", duration: 0.3)
    }
}
