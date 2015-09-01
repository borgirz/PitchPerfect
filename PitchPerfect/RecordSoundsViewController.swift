//
//  RecordSoundsViewController.swift
//  PitchPerfect
//
//  Created by Nicolas Jasmes on 13/08/15.
//  Copyright (c) 2015 Nicolas Jasmes. All rights reserved.
//

import UIKit
import AVFoundation

final class RecordSoundsViewController: UIViewController, AVAudioRecorderDelegate {

    // MARK: Properties
    // ****************
    
    // User's document directory
    let userDocumentFolderPath: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    
    // Recorder
    var audioRecorder: AVAudioRecorder?
    
    // Timer variables to display recorded time
    var timer: NSTimer = NSTimer()
    var counter: Int = 0
    
    
    
    // MARK: Outlets
    // **************
    
    @IBOutlet weak var lblTimer: UILabel!
    @IBOutlet weak var btnRecord: UIButton!
    @IBOutlet weak var lblRecordingStatus: UILabel!
    @IBOutlet weak var btnPause: UIButton!
    @IBOutlet weak var btnStop: UIButton!
    @IBOutlet weak var btnResume: UIButton!
    
    
    
    // MARK: ViewController Lifecycle
    // ******************************
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the record button image to be identical if disabled to create a better fading in & out effects during record, if "nil" => still works as the button still exists
        // Source : http://stackoverflow.com/questions/7542950/how-do-you-change-uibutton-image-alpha-on-disabled-state
        
        btnRecord.setBackgroundImage(btnRecord.imageView?.image, forState: UIControlState.Disabled)
    }

    override func viewWillAppear(animated: Bool) {
        
        // Set UI Elements to their initial state
        resetUIElements()
    }
    
    
    
    // MARK: Actions triggered by UI Elements
    // **************************************
    
    
    @IBAction func startRecording(sender: UIButton) {
        
        // Disable record button
        btnRecord.enabled = false
        
        // Show recorder buttons
        btnStop.hidden = false
        btnPause.hidden = false
        btnResume.hidden = false
        
        // Show timer
        lblTimer.hidden = false
        
        // Change Recording status label
        lblRecordingStatus.text = "Record in progress..."
        
        // Start flashing animation for the record button (From CustomViewAnimationsFunctions.swift)
        flashViewWithFadingTransition(btnRecord)
        
        // Setup and start an audio session
        var audioSession = AVAudioSession.sharedInstance()
        audioSession.setCategory(AVAudioSessionCategoryRecord, error: nil)
        
        // Setup recorder for m4a file format.
        // Source : http://stackoverflow.com/questions/27809475/avaudiorecorder-recording-m4a-files-that-are-very-large
        let recordSettings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderAudioQualityKey : AVAudioQuality.Medium.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey : 44100.0
        ]
        
        // Assign new path to the recorder (re)initialise it
        audioRecorder = AVAudioRecorder(URL: newFilePathBasedOnCurrentTime(), settings: recordSettings as [NSObject: AnyObject], error: nil)
        
        
        // If the audio recorder still exists : No errors
        if let audioRecorder = audioRecorder{
    
            // Record
            audioRecorder.delegate = self // To be able to use audioRecorderDidFinishRecording delegate method
            audioRecorder.meteringEnabled = true
            audioRecorder.prepareToRecord()
            audioRecorder.record()
            
            // Start timer - Perform updateCounterLabel() every second
            // Source: https://github.com/UrbanApps/UAProgressView/issues/5
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("updateCounterLabel"), userInfo: nil, repeats: true)
        }
    }
    
    
    @IBAction func stopRecording(sender: UIButton) {
        
        // If the recorder still exists
        if let audioRecorder = audioRecorder{
            
            // Stop recording
            audioRecorder.stop()
            
            // Stop the timer
            timer.invalidate()
            
            // Stop all animations for record button
            stopAllAnimations(btnRecord)
            
            // Desactivate the audio session
            let audioSession = AVAudioSession.sharedInstance()
            audioSession.setActive(false, error: nil)
        }
    }
    
    
    @IBAction func pauseRecording(sender: UIButton) {
        
        // If the recorder still exists
        if let audioRecorder = audioRecorder{
            
            // Pause recording
            audioRecorder.pause()
            
            // Pause the timer
            timer.invalidate()
            
            // Disable pause button"
            btnPause.enabled = false
            
            // Enable resume button"
            btnResume.enabled = true
            
            // Change Recording status label
            lblRecordingStatus.text = "Record in pause"
            
            // Stop All Animation for record button & Set opacity to 0.5
            stopAllAnimations(btnRecord)
            btnRecord.alpha = 0.5
        }
    }
    
    @IBAction func resumeRecording(sender: UIButton) {
        
        // If the recorder still exists
        if let audioRecorder = audioRecorder{
            
            // Resume recording
            audioRecorder.record()
            
            // Restart (resume) timer - Perform updateCounterLabel() every second
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("updateCounterLabel"), userInfo: nil, repeats: true)
            
            // Disable resume button
            btnResume.enabled = false
            
            // Enable pause button
            btnPause.enabled = true
            
            // Change Recording status label
            lblRecordingStatus.text = "Record in progress..."
            
            // Start flashing animation for the record button
            flashViewWithFadingTransition(btnRecord)
        }
    }
 
    
    
    // MARK: Recorder delagated functions
    // **********************************
    
    // Is triggered when the audio recorder finishes the recording. Perform the segue to PlaySoundsViewController
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        
        // If the recording is successfull
        if(flag){
            
            // Create a new audio "file" which target the recorded file -- a bit redundant as I could have created the AVAudioFile directly with its own initialiser, but likethis it uses the new class and a custom initialiser to follow code improvements directives
            let recordedAudioFile: AVAudioFile = RecordedAudio(filePathUrl: recorder.url).asAVAudioFile()
            
            // Perform segue to PlaySoundsViewController
            performSegueWithIdentifier("gotoPlaySoundsViewController", sender: recordedAudioFile)
        }
            
        // If the recording is unsuccessfull
        else{
            
            // Popup an alert message
            // TODO : http://stackoverflow.com/questions/28137259/how-do-i-code-an-uialertaction-in-swift
            var alert = UIAlertController(title: "Error", message: "Recording fails due to an unknown error", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
            
            // Reset UI to its initial state
            resetUIElements()
        }
    }
    
    
    
    // MARK: Custom functions
    // **********************
    
    // Return a new unique file path based on the current date/time
    func newFilePathBasedOnCurrentTime() -> NSURL!{
        
        let currentDateTime = NSDate()
        var formatter = NSDateFormatter()
        formatter.dateFormat = "ddMMyyyy-HHmmss"
        let recordingName = "PitchPerfect_"+formatter.stringFromDate(currentDateTime)+".m4a"
        let pathArray = [userDocumentFolderPath, recordingName]
        return NSURL.fileURLWithPathComponents(pathArray)
    }
    
    // Update the timer label based on counter value
    func updateCounterLabel() {
        
        ++counter
        var tempCounterTxt = ""
        
        // Minutes
        tempCounterTxt +=  "\(counter / 60)"
        tempCounterTxt +=  ":"
        
        // Add a "0" if seconds are < 10
        if ((counter % 60) < 10){
            tempCounterTxt += "0"
        }
        
        // Seconds
        tempCounterTxt += "\(counter % 60)"
        lblTimer.text = tempCounterTxt
    }
    
    // Set UI Objects to their initial status
    func resetUIElements(){
        
        // Set "initial" values
        lblTimer.text = "00:00"                     // Re-initialise timer
        lblRecordingStatus.text = "Tap to record !" // Re-initialise status
        btnRecord.alpha = 1.0                       // Re-initialise record button opacity
        counter = 0                                 // Re-initialise the counter
        lblTimer.text = "0:00"                      // Set timer label to default value
        
        // Enable-Disable interractive outlet(s) (Buttons, text fields, ...)
        // @ Enabled
        btnRecord.enabled = true
        btnPause.enabled = true
        btnStop.enabled = true
        // @ Disabled
        btnResume.enabled = false
        
        // Show-Hide outlet(s)
        // @ Visible
        btnRecord.hidden = false
        lblRecordingStatus.hidden = false
        // @ Hidden
        lblTimer.hidden = true
        btnPause.hidden = true
        btnStop.hidden = true
        btnResume.hidden = true
    }
    
    
    
    // MARK: Prepare for Segue
    // ***********************
        
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // If manual segue is "gotoPlaySoundsViewController"
        if (segue.identifier == "gotoPlaySoundsViewController"){
            
            // Define the new controller and pass the audiofile as external parameter
            let playSoundVC: PlaySoundsViewController = segue.destinationViewController as! PlaySoundsViewController
            let data = sender as! AVAudioFile?
            playSoundVC.audioFile = data
        }
    }
}

// EOF
