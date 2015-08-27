//
//  PlaySoundsViewController.swift
//  PitchPerfect
//
//  Created by Nicolas Jasmes on 13/08/15.
//  Copyright (c) 2015 Nicolas Jasmes. All rights reserved.
//

import UIKit
import AVFoundation

class PlaySoundsViewController: UIViewController {

    
    // MARK: Properties
    // ****************
    
    // Audio file - external from segue
    var audioFile:AVAudioFile?
    
    // Audio engine & player node
    var audioEngine:AVAudioEngine! // Will be reinitialised on each reading
    let audioPlayerNode: AVAudioPlayerNode = AVAudioPlayerNode() // Will never change
    
    // Array of audio nodes that should be inserted between the player node and the output node
    var chainOfNodes = [AVAudioNode]()
    
    
    
    // MARK: Outlets
    // **************
    
    @IBOutlet weak var lblPlayingStatus: UILabel!
    @IBOutlet weak var btnStop: UIButton!
    
    
    
    // MARK: ViewController Lifecycle
    // ******************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // Set UI Objects to their initial status
        // --------------------------------------
        
        // Set "initial" values
        lblPlayingStatus.text = "Select your effect !" //re-initialise status
        
        // Enable-Disable interractive outlet(s) (Buttons, text fields, ...)
        // @ Enabled
        btnStop.enabled = true
        
        // Show-Hide outlet(s)
        // @ Hidden
        btnStop.hidden = true
    }

    
    @IBAction func playSlow(sender: UIButton) {
        
        playSoundWithEffects("Playing... Slow",speedRate: 0.5,pitch: 1200, reverb: nil, echo: nil)
    }
    
    @IBAction func playFast(sender: UIButton) {
        
        playSoundWithEffects("Playing... Fast",speedRate: 1.5,pitch: -700, reverb: nil, echo: nil)
    }
    
    @IBAction func playChipmunk(sender: UIButton) {
        
        playSoundWithEffects("Playing... Chipmunk",speedRate: nil,pitch: 1000, reverb: nil, echo: nil)

    }
    
    @IBAction func playDarthVador(sender: UIButton) {
        
        playSoundWithEffects("Playing... Darth Vador",speedRate: nil,pitch: -1000, reverb: nil, echo: nil)
    }
    
    @IBAction func playEcho(sender: UIButton) {
        
        playSoundWithEffects("Playing... Echo",speedRate: nil,pitch: nil, reverb: nil, echo: 0.7)
    }

    @IBAction func playReverb(sender: UIButton) {
        
        playSoundWithEffects("Playing... Reverb",speedRate: nil,pitch: nil, reverb: 50, echo: nil)
    }
    
    @IBAction func stop(sender: UIButton?) {
        
        // Stop the audio Engine
        audioEngine.stop()
        
        //disable stop button
        btnStop.enabled = false
        btnStop.hidden = true
        
        //Stop flashing animation on playing status label & set opacity to 1.0
        stopAllAnimations(lblPlayingStatus)
        lblPlayingStatus.alpha = 1.0
        
        //Change Playing status label
        lblPlayingStatus.text = "Select your effect !"
        
    }
    
    
    func resetAudioEngine() -> Void{
        
        if let audioEngine = audioEngine{
            audioEngine.stop()
        }
        while(chainOfNodes.count != 0){
            var node = chainOfNodes.removeLast()
            audioEngine.detachNode(node)
        }
        audioEngine = nil
    }
    
    func playSoundWithEffects(message: String, speedRate: Float?, pitch: Float?, reverb: Float?, echo: Float?) -> Void {
        
        var speedRate = speedRate
        
        
        // Enable stop button
        btnStop.enabled = true
        btnStop.hidden = false
        
        // Stop flashing animation on playing status
        stopAllAnimations(lblPlayingStatus)
        
        // Set playing status message
        lblPlayingStatus.text = message
        
        // Start flashing animation for the playing status label
        flashViewWithFadingTransition(lblPlayingStatus)
        
        
        //TODO: Reset Audio Engine
        resetAudioEngine()
        
        audioEngine = AVAudioEngine()
        audioEngine.attachNode(audioPlayerNode)
        
        
        
        if let pitchLevel = pitch{
            let pitchEffectNode = AVAudioUnitTimePitch()
            pitchEffectNode.pitch = pitchLevel
            chainOfNodes.append(pitchEffectNode)
        }
        
        if let rate = speedRate{
            let changeSpeedEffectNode = AVAudioUnitVarispeed()
            changeSpeedEffectNode.rate = rate
            chainOfNodes.append(changeSpeedEffectNode)
        }
        
        
        if let wetDryMixLevel = reverb{
            let reverbEffectNode = AVAudioUnitReverb()
            reverbEffectNode.wetDryMix = wetDryMixLevel
            chainOfNodes.append(reverbEffectNode)
        }
        
        if let echoLevel = echo{
            let echoEffectNode = AVAudioUnitDelay()
            echoEffectNode.delayTime = NSTimeInterval(echoLevel)
            chainOfNodes.append(echoEffectNode)
        }
        
        
        for node in chainOfNodes{
            audioEngine.attachNode(node)
        }
        
        if chainOfNodes.count != 0{
            var index = 0
            audioEngine.connect(audioPlayerNode, to: chainOfNodes[index], format: nil)
            while(index < chainOfNodes.count-1){
                audioEngine.connect(chainOfNodes[index], to: chainOfNodes[++index], format: nil)
            }
            audioEngine.connect(chainOfNodes[index], to: audioEngine.outputNode, format: nil)
        }
        else{
            audioEngine.connect(audioPlayerNode, to: audioEngine.outputNode, format: nil)
        }
        
        
        audioPlayerNode.stop()
        
        let buffer = AVAudioPCMBuffer(PCMFormat: audioFile!.processingFormat, frameCapacity: AVAudioFrameCount(audioFile!.length))
        
        //audioFile?.readIntoBuffer(buffer, error: nil)
        
        let buffer2 = AVAudioPCMBuffer(PCMFormat: audioFile!.processingFormat, frameCapacity: AVAudioFrameCount(audioFile!.length))
        
        audioFile?.readIntoBuffer(buffer2, error: nil)
        
        //audioPlayerNode.scheduleBuffer(buffer, atTime: nil, options: nil, completionHandler: nil)
        audioPlayerNode.scheduleBuffer(buffer2, atTime: nil, options: .interrupt, completionHandler:  audioPlayerNode.play)
        audioEngine.startAndReturnError(nil)
        
        audioPlayerNode.play()
        
        
    }

    
    func stopPlayingHandler(){
       /*
        // Stop the audio Engine
        audioEngine.stop()
        
        dispatch_async(dispatch_get_main_queue(), {
            //disable stop button
            self.btnStop.enabled = false
            self.btnStop.hidden = true
            
            //Stop flashing animation on playing status label & set opacity to 1.0
            stopAllAnimations(self.lblPlayingStatus)
            self.lblPlayingStatus.alpha = 1.0
            
            //Change Playing status label
            self.lblPlayingStatus.text = "Select your effect !"
        })
        */
    }
    
}
