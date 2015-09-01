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
    var audioEngine:AVAudioEngine?
    var audioPlayerNode: AVAudioPlayerNode?

    var buffer : AVAudioPCMBuffer!
    
    var chainOfNodes: [AVAudioNode] = []
    
    // Counter incremented each time the user is pressing an effect button an decremented when a file finish reading (or is interrupted)
    var playingCounter = 0
    
    
    // MARK: Outlets
    // **************
    
    
    @IBOutlet weak var lblPlayingStatus: UILabel!
    @IBOutlet weak var btnStop: UIButton!
    
    @IBOutlet var btnsEffect: [UIButton]!
    
    
    // MARK: ViewController Lifecycle
    // ******************************
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        audioEngine = AVAudioEngine()
        createAudioPlayerNodeAndAttachItToAudioEngine()
        
        buffer = AVAudioPCMBuffer(PCMFormat: audioFile!.processingFormat, frameCapacity: AVAudioFrameCount(audioFile!.length))
        audioFile?.readIntoBuffer(buffer, error: nil)

    }
    
    override func viewWillDisappear(animated: Bool) {
        
        stopPlaying(true)
        deleteAudioEngine()
        buffer = nil


    }
    
    override func viewWillAppear(animated: Bool) {
        
        resetUIToInitialState()
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

        stopPlaying(true)
        
    }
    
    func deleteAudioEngine(){
        cleanAudioEngine()
        audioEngine = nil
    }
    
    
    func cleanAudioEngine() -> Void{
        
        audioPlayerNode?.stop()
        audioEngine?.stop()
        
        audioEngine?.disconnectNodeOutput(audioPlayerNode)
        audioEngine?.detachNode(audioPlayerNode)
        
        cleanChainOfNodes()
        
        audioPlayerNode = nil
    }
    
    func resetAudioEngine() -> Void{
        cleanAudioEngine()
        createAudioPlayerNodeAndAttachItToAudioEngine()
    }
    
    func createAudioPlayerNodeAndAttachItToAudioEngine() -> Void{

        audioPlayerNode = AVAudioPlayerNode()
        audioEngine?.attachNode(audioPlayerNode)
    }
    
    func cleanChainOfNodes() -> Void{
    
        for node in chainOfNodes{
            audioEngine?.disconnectNodeOutput(node)
            audioEngine?.detachNode(node)
        }
    
        while(chainOfNodes.count != 0){
            var node = chainOfNodes.removeLast()
        }
    }
    
    func playSoundWithEffects(message: String, speedRate: Float?, pitch: Float?, reverb: Float?, echo: Float?) -> Void{
        
        playingCounter++
        
    /// Reset AudioEngine
        resetAudioEngine()
        
        
    /// Create effect nodes
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

    /// Attach Nodes
        
        for node in chainOfNodes{
            audioEngine?.attachNode(node)
        }
        
    /// Connect Nodes (audioPlayerNode -> ChainOfNodes -> audioEngine.outputNode)
        
        if chainOfNodes.count != 0{
            var index = 0
            audioEngine?.connect(audioPlayerNode, to: chainOfNodes[index], format: nil)
            while(index < chainOfNodes.count-1){
                println("loop")
                audioEngine?.connect(chainOfNodes[index], to: chainOfNodes[++index], format: nil)
            }
            audioEngine?.connect(chainOfNodes[index], to: audioEngine?.outputNode, format: nil)
        }
        else{
            audioEngine?.connect(audioPlayerNode, to: audioEngine?.outputNode, format: nil)
        }
        
    /// Start Audio Session
        
        var audioSession = AVAudioSession.sharedInstance()
        audioSession.setCategory(AVAudioSessionCategoryPlayback, error: nil)
        
    /// Start the audioEngine
         audioEngine?.startAndReturnError(nil)
    
    /// Schedule the buffer and start playing
        audioPlayerNode?.scheduleBuffer(buffer, atTime: nil, options: .Interrupts, completionHandler: stopPlayingHandler)
        audioPlayerNode?.play()

        /// Start Animation
        updateUIForPlaying(message)
        //changeEffectsButtonsToEnabledStatus(false)
        
    }
    
    
    func stopPlayingHandler(){
        
        playingCounter--
        dispatch_async(dispatch_get_main_queue(), {

            if self.playingCounter == 0{
                self.stopPlaying(false)
            }
        })
    }
    
    func updateUIForPlaying(labelText: String){
        // Enable stop button
        btnStop.enabled = true
        btnStop.hidden = false
        
        // Stop flashing animation on playing status
        stopAllAnimations(lblPlayingStatus)
        
        // Set playing status text
        lblPlayingStatus.text = labelText
        
        // Start flashing animation for the playing status label
        flashViewWithFadingTransition(lblPlayingStatus)
    }
    
    func resetUIToInitialState(){
        
        //disable stop button
        btnStop.enabled = false
        btnStop.hidden = true
        
        //Stop flashing animation on playing status label & set opacity to 1.0
        stopAllAnimations(self.lblPlayingStatus)
        lblPlayingStatus.alpha = 1.0
        
        //Change Playing status label
        lblPlayingStatus.text = "Select your effect !"
        
        changeEffectsButtonsToEnabledStatus(true)
    }
    
    func changeEffectsButtonsToEnabledStatus(status: Bool){
        for button in btnsEffect{
            button.enabled = status
        }
    }
    
    // Stop playing and restore UI to initial state, if needed, stop the engine too (for stop button, other effect, like echo will continue playing if stopEngine=false)
    func stopPlaying(stopEngine: Bool){
        
        audioPlayerNode?.stop()
        
        if stopEngine{
            audioEngine?.stop()
        }
        
        var audioSession = AVAudioSession.sharedInstance()
        audioSession.setActive(false, error: nil)
        
        resetUIToInitialState()
    }
}

// EOF

