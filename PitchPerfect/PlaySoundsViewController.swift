//
//  PlaySoundsViewController.swift
//  PitchPerfect
//
//  Created by Nicolas Jasmes on 13/08/15.
//  Copyright (c) 2015 Nicolas Jasmes. All rights reserved.
//

import UIKit
import AVFoundation

final class PlaySoundsViewController: UIViewController {
    
    
    // MARK: Properties
    // ****************
    
    // Audio file - external from segue
    var audioFile: AVAudioFile?
    // Audio engine & player node
    var audioEngine: AVAudioEngine?
    var audioPlayerNode: AVAudioPlayerNode?
    
    // Audio buffer
    var buffer: AVAudioPCMBuffer?
    
    // Array of audio nodes that will be recreated for every playing. Will only contains needed nodes. Will be used to connect them each other.
    var chainOfNodes: [AVAudioNode] = []
    
    // Counter incremented each time the user is pressing an effect button an decremented when a file finish reading (or is interrupted)
    var playingCounter = 0
    
    
    
    // MARK: Outlets
    // **************
    
    @IBOutlet weak var lblPlayingStatus: UILabel!
    @IBOutlet weak var btnStop: UIButton!
    

    
    // MARK: ViewController Lifecycle
    // ******************************
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Initialise audio engine and attach a new audio player node
        audioEngine = AVAudioEngine()
        createAudioPlayerNodeAndAttachItToAudioEngine()
        
        // Verify if the audiofile is not nil (it should normally never happens in this application => Only if we call the viewcontroller with another segue with no parameters
        if let audioFile = audioFile{
            // Create a buffer and fill it with the content of the audio file
            buffer = AVAudioPCMBuffer(PCMFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length))
            audioFile.readIntoBuffer(buffer, error: nil)
        }
        else{
            // Return to root view controller
            self.navigationController?.popToRootViewControllerAnimated(true)
        }

    }
    
    override func viewWillDisappear(animated: Bool) {
        
        // Stop playing, stop the engine, stop the audio session
        stopPlaying(true)
        
        // Clean and delete the audio engine (desalloc & detach nodes)
        deleteAudioEngine()
        
        // Reset buffer
        buffer = nil
    }
    
    override func viewWillAppear(animated: Bool) {
        
        // Reset UI (buttons & labels) to initial state
        resetUIToInitialState()
    }
    
    
    
    // MARK: Actions triggered by UI Elements
    // **************************************
    

    @IBAction func playSlow(sender: UIButton) {
        // Info : As changing the speedRate using AVAudioUnitVarispeed also modify the pitch, I increase the pitch effect value to 1200 to recover normal voice pitch level.
        playSoundWithEffects("Playing... Slow",speedRate: 0.5,pitch: 1200, reverb: nil, echo: nil)
    }
    
    @IBAction func playFast(sender: UIButton) {
        // Info : As changing the speedRate using AVAudioUnitVarispeed also modify the pitch, I decrease the pitch effect value to -700 to recover normal voice pitch level.
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

        // Stop playing, stop the engine, stop the audio session => volontary stop the echo effect too
        stopPlaying(true)
    }
    
    
    
    // MARK: Custom functions
    // **********************
    
    // Play audio file loaded in the buffer in the audio engine, with effect.
    func playSoundWithEffects(message: String, speedRate: Float?, pitch: Float?, reverb: Float?, echo: Float?){

        // Count the number of times the user clicks on a button that trigger the playSoundWithEffects method
        playingCounter++
        
        // Reset the audio engine
        resetAudioEngine()
        
        // Create effect nodes if needed and add them to the node array "chainOfNodes"
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
        
        // Attach to the audio engine all nodes in the array "chainOfNodes"
        for node in chainOfNodes{
            audioEngine?.attachNode(node)
        }
        
        // Start the audio Session
        let audioSession = AVAudioSession.sharedInstance()
        audioSession.setCategory(AVAudioSessionCategoryPlayback, error: nil)
        
        // Connect all nodes to each other sequentially (audioPlayerNode -> ChainOfNodes -> audioEngine.outputNode)
        if chainOfNodes.count != 0 {
            var index = 0
            audioEngine?.connect(audioPlayerNode, to: chainOfNodes[index], format: nil)
            while(index < chainOfNodes.count-1){
                audioEngine?.connect(chainOfNodes[index], to: chainOfNodes[++index], format: nil)
            }
            audioEngine?.connect(chainOfNodes[index], to: audioEngine?.outputNode, format: nil)
        }
        else{
            audioEngine?.connect(audioPlayerNode, to: audioEngine?.outputNode, format: nil)
        }
        
        /// Start the audioEngine
        audioEngine?.startAndReturnError(nil)
        
        /// Schedule the buffer and start playing
        audioPlayerNode?.scheduleBuffer(buffer, atTime: nil, options: .Interrupts, completionHandler: stopPlayingHandler)
        audioPlayerNode?.play()
        
        /// Start labael animation & activate the stop button
        updateUIForPlaying(message)
        
    }
    
    // Stop playing and restore UI to initial state, if needed, stop the engine too (for stop button. Other effects, like echo will continue playing if stopEngine = false)
    func stopPlaying(stopEngine: Bool){
        
        audioPlayerNode?.stop()
        
        if stopEngine{
            audioEngine?.stop()
            let audioSession = AVAudioSession.sharedInstance()
            audioSession.setActive(false, error: nil)
        }
        
        // Reset UI (Hide & disable the stop button, stop animating the label and reset it to "Select your effect)
        resetUIToInitialState()
    }
    
    // Triggerd when the audioPlayerNode stops playing the content of the buffer or is interrupted
    func stopPlayingHandler(){
        
        playingCounter--
        
        // Asynchronously trigger the stopPlaying method if there is no playing in progress. Will never stop the engine to allow effects like echo to continue.
        dispatch_async(dispatch_get_main_queue(), {
            if self.playingCounter == 0{
                self.stopPlaying(false)
            }
        })
    }
    
    // Show & Enable the stop button, change the text label and animate it
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
    
    // Reset UI (Hide & disable the stop button, stop animating the label (+ other animations if there are) and reset it to "Select your effect)
    func resetUIToInitialState(){
        
        //disable stop button
        btnStop.enabled = false
        btnStop.hidden = true
        
        //Stop flashing animation on playing status label & set opacity to 1.0
        stopAllAnimations(self.lblPlayingStatus)
        lblPlayingStatus.alpha = 1.0
        
        //Change Playing status label
        lblPlayingStatus.text = "Select your effect !"
        
    }
    
    // Clean the audio engine : Stop the audio engine, disconnect and detach all nodes and reset (unassign) the audioPlayerNode
    func cleanAudioEngine(){
        
        audioPlayerNode?.stop()
        audioEngine?.stop()
        
        audioEngine?.disconnectNodeOutput(audioPlayerNode)
        audioEngine?.detachNode(audioPlayerNode)
        
        cleanChainOfNodes()
        
        audioPlayerNode = nil
    }
    
    // Clean the audio engine and reset (unassign) it
    func deleteAudioEngine(){
        cleanAudioEngine()
        audioEngine = nil
    }
    
    // Clean the audio engine, recreate the audioPlayerNode and attach it.
    func resetAudioEngine(){
        cleanAudioEngine()
        createAudioPlayerNodeAndAttachItToAudioEngine()
    }
    
    // Create an audio player node and attach it to the engine (P.S.: The audio engine always exists. It will be reset only on viewWillDisappear)
    func createAudioPlayerNodeAndAttachItToAudioEngine() -> Void{

        audioPlayerNode = AVAudioPlayerNode()
        audioEngine?.attachNode(audioPlayerNode)
    }
    
    // Will, for each AVAudioNode in the array, disconnect its output node and detach it from the engine. the method will then remove them one by one until the array is empty
    func cleanChainOfNodes(){
    
        for node in chainOfNodes{
            audioEngine?.disconnectNodeOutput(node)
            audioEngine?.detachNode(node)
        }
    
        while(chainOfNodes.count != 0){
            let node = chainOfNodes.removeLast()
        }
    }
}

// EOF

