//
//  WWSimplifiedMusicalNotationPlayer.swift
//  WWSimplifiedMusicalNotationPlayer
//
//  Created by William.Weng on 2025/3/10.
//

import AVFoundation
import WWTwelveEqualTemperament

// MARK: - 簡譜播放器
open class WWSimplifiedMusicalNotationPlayer {
    
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()

    private var isPedalOn = false
    private var noteFrequencyTable: [String: Double] = [:]
    private var lastNoteBuffer: AVAudioPCMBuffer?
    
    public init() { initSetting() }
}

// MARK: - 公開函式
public extension WWSimplifiedMusicalNotationPlayer {
    
    /// [播放簡譜音符](https://william-weng.github.io/2025/01/eop簡譜大師讓我們一起成為大師吧/)
    /// - Parameters:
    ///   - note: [簡譜音符](https://zh.soundoflife.com/blogs/experiences/numbered-musical-notation)
    ///   - duration: 播放時間
    ///   - pedalOnDuration: 踏板延音持續時間
    /// - Returns: Result<Bool, Error>
    func playNote(_ note: String, duration: Double = 0.35, pedalOnDuration: Double = 3.0) -> Result<Bool, Error> {
        guard let frequency = noteFrequencyTable[note] else { return .failure(NotationError.noteNotInTable) }
        return playNote(frequency: frequency, duration: duration, pedalOnDuration: pedalOnDuration)
    }
    
    /// [播放頻率聲音](https://youtu.be/nX8ZmcIJQhU)
    /// - Parameters:
    ///   - frequency: [頻率](https://tmrc.tiec.tp.edu.tw/HTML/RSR20081124231639YLZ/content/wave2-1-2.html)
    ///   - duration: [單音持續時間](https://kkbox.github.io/kkbox-ios-dev/audio_apis/avaudioengine.html)
    ///   - pedalOnDuration: 踏板延音持續時間
    /// - Returns: Result<Bool, Error>
    func playNote(frequency: CGFloat, duration: Double = 0.35, pedalOnDuration: Double = 3.0) -> Result<Bool, Error> {
        
        let outputFormat = audioFormatMaker(engine, forBus: 0)
        let totalDuration = isPedalOn ? duration + pedalOnDuration : duration
        
        guard let standardFormat = standardFormatMaker(outputFormat) else { return .failure(NotationError.audioFormat) }
        guard let buffer = audioPCMBufferMaker(audioFormat: standardFormat, duration: totalDuration) else { return .failure(NotationError.audioPCMBuffer) }
        
        envelope(buffer: buffer, audioFormat: standardFormat, frequency: frequency, duration: totalDuration)
        
        player.scheduleBuffer(buffer)
        player.play()
        
        lastNoteBuffer = buffer
        
        return .success(true)
    }
    
    /// [播放簡譜](https://medium.com/彼得潘的-swift-ios-app-開發問題解答集/使用-ai-製作的-simplepianosynthesizer-彈鋼琴-4657a94e14a1)
    /// - Parameters:
    ///   - song: 簡譜
    ///   - duration: 單音持續時間
    ///   - pedalOnDuration: 踏板延音持續時間
    ///   - result: ((Result<Bool, Error>) -> Void)?
    func playSong(_ song: String, duration: Double = 0.35, pedalOnDuration: Double = 3.0, result: ((Result<Bool, Error>) -> Void)? = nil)  {
        
        let infos = parseNotation(song, duration: duration)
        
        for info in infos {
            
            let playResult = playNote(frequency: info.frequency, duration: info.duration, pedalOnDuration: pedalOnDuration)
            
            switch playResult {
            case .failure(_): result?(.failure(NotationError.playNote(info.note)))
            case .success(let isSuccess): result?(.success(isSuccess))
            }
            
            Thread.sleep(forTimeInterval: info.duration)
        }
    }
    
    /// [踏板控制方法 (釋放踏板時清除上一個音符緩衝區)](https://bideyuanli.com/声乐基础理论/音高)
    /// - Parameter on: Bool
    func pedal(on: Bool) {
        isPedalOn = on
        if !isPedalOn { lastNoteBuffer = nil }
    }
}

// MARK: - 小工具
private extension WWSimplifiedMusicalNotationPlayer {
    
    /// 初始化設定
    func initSetting() {
        
        initNoteFrequencyTable()
        
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        
        do {
            try engine.start()
        } catch {
            print("無法啟動音頻引擎: \(error)")
        }
    }
    
    /// 初始化音符頻率對照表
    func initNoteFrequencyTable() {
        noteFrequencyTable = WWTwelveEqualTemperament.shared.pianoTable(type: .number)
    }
    
    /// 產生AVAudioFormat
    /// - Parameters:
    ///   - engine: AVAudioEngine
    ///   - bus: AVAudioNodeBus
    /// - Returns: AVAudioFormat
    func audioFormatMaker(_ engine: AVAudioEngine, forBus bus: AVAudioNodeBus) -> AVAudioFormat {
        return engine.outputNode.outputFormat(forBus: bus)
    }
    
    /// 產生標準化的AVAudioFormat
    /// - Parameter outputFormat: AVAudioFormat
    /// - Returns: AVAudioFormat?
    func standardFormatMaker(_ outputFormat: AVAudioFormat) -> AVAudioFormat? {
        return AVAudioFormat(standardFormatWithSampleRate: outputFormat.sampleRate, channels: outputFormat.channelCount)
    }
    
    /// 產生AVAudioPCMBuffer
    /// - Parameters:
    ///   - audioFormat: AVAudioFormat
    ///   - duration: Double
    /// - Returns: AVAudioPCMBuffer?
    func audioPCMBufferMaker(audioFormat: AVAudioFormat, duration: Double) -> AVAudioPCMBuffer? {
        
        let frameCount = AVAudioFrameCount(audioFormat.sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)
        
        buffer?.frameLength = frameCount

        return buffer
    }
    
    /// [Envelope (波封) - ADSR](https://vocus.cc/article/64ed72c5fd89780001569b27)
    /// - Parameters:
    ///   - buffer: [AVAudioPCMBuffer](https://youtu.be/0Nw5y9E-TaY)
    ///   - audioFormat: [AVAudioFormat](https://youtu.be/d8ge7QmZbcc)
    ///   - frequency: CGFloat
    ///   - duration: Double
    ///   - pedalOnDuration: Double
    func envelope(buffer: AVAudioPCMBuffer, audioFormat: AVAudioFormat, frequency: CGFloat, duration: Double, pedalOnDuration: Double = 3.0) {
        
        let frameCount = AVAudioFrameCount(audioFormat.sampleRate * duration)

        // ADSR 參數
        let attackTime = 0.01
        let decayTime = 0.1
        let sustainLevel = 0.7
        let releaseTime = 0.3
        
        for channel in 0..<Int(audioFormat.channelCount) {
            
            guard let channelData = buffer.floatChannelData?[channel] else { continue }
            
            for frame in 0..<Int(frameCount) {
                
                let t = Double(frame) / audioFormat.sampleRate
                
                // 基本音調
                var value = sin(2.0 * .pi * Double(frequency) * t)
                
                // 添加諧波
                value += 0.5 * sin(4.0 * .pi * Double(frequency) * t)
                value += 0.25 * sin(6.0 * .pi * Double(frequency) * t)
                value += 0.125 * sin(8.0 * .pi * Double(frequency) * t)
                
                // 應用 ADSR 包絡線
                let envelopeValue: Double
                
                if t < attackTime {
                    envelopeValue = t / attackTime
                } else if t < attackTime + decayTime {
                    envelopeValue = 1.0 - (1.0 - sustainLevel) * ((t - attackTime) / decayTime)
                } else if t < duration - releaseTime {
                    envelopeValue = sustainLevel
                } else {
                    let releaseProgress = (t - duration) / releaseTime
                    envelopeValue = sustainLevel * (isPedalOn ? (1.0 - pow(releaseProgress, 0.3)) : (1.0 - releaseProgress))
                }
                
                // 應用衰減 => 大幅減緩衰減
                let decay = pow(0.5, t / (isPedalOn ? pedalOnDuration : 0.5))
                
                // 根據頻率調整音量
                let volumeAdjustment = min(1.0, sqrt(1000 / Double(frequency)))
                
                // 添加共鳴效果
                var finalValue = value * envelopeValue * decay * volumeAdjustment * 0.3
                
                if isPedalOn {
                    finalValue += sin(2.0 * .pi * Double(frequency / 2) * t) * 0.05 * decay  // 添加低頻共鳴
                    finalValue += sin(2.0 * .pi * Double(frequency * 2) * t) * 0.03 * decay  // 添加高頻共鳴
                }
                
                channelData[frame] = Float(finalValue)
            }
        }
    }
        
    /// 解析簡譜 => (頻率, 持續時間)
    /// - Returns: [(CGFloat, Double)]
    /// - Parameters:
    ///   - notation: 音符
    ///   - duration: 持續時間
    func parseNotation(_ notation: String, duration: Double) -> [NoteInformation] {
        
        let notes = notation.components(separatedBy: .whitespaces)
        
        var result: [NoteInformation] = []
        
        for note in notes {
            
            var duration = duration
            var noteKey = note
            var info: NoteInformation = (note, 0, 0)
            
            // 處理延長音符
            if note.hasSuffix("~") {
                noteKey = String(note.dropLast())
                duration *= 2
            }
            
            // 記錄音頻 / 持續時間
            if let frequency = noteFrequencyTable[noteKey] {
                info.frequency = frequency
                info.duration = duration
            }
            
            result.append(info)
        }
        
        return result
    }
}
