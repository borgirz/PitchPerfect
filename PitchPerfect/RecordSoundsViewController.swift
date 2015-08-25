//
//  RecordSoundsViewController.swift
//  PitchPerfect
//
//  Created by Nicolas Jasmes on 13/08/15.
//  Copyright (c) 2015 Nicolas Jasmes. All rights reserved.
//

import UIKit
import AVFoundation

class RecordSoundsViewController: UIViewController, AVAudioRecorderDelegate {

    // MARK: Properties
    // ****************
    
    // User's document directory
    let userDocumentFolderPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    
    // Recorder
    var audioRecorder: AVAudioRecorder?
    
    // Audio file => For segue
    var recordedAudioFile: AVAudioFile?
    
    // Timer variables to display recorded time
    var timer = NSTimer()
    var counter : Int = 0
    
    
    
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
        
        // Set UI Objects to their initial status
        // --------------------------------------
        
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
        audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, error: nil)
        
        // Assign new path to the recorder (re)initialise it
        audioRecorder = AVAudioRecorder(URL: newFilePathBasedOnCurrentTime(), settings: nil, error: nil)
        
        
        
        //////////ICICICICICI
        
        
        // if the audio recorder still exists
        if let audioRecorder = audioRecorder{
            
            // record
            audioRecorder.delegate = self
            audioRecorder.meteringEnabled = true
            audioRecorder.prepareToRecord()
            audioRecorder.record()
            
            // start timer
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: Selector("updateCounter"), userInfo: nil, repeats: true)
        }

    }
    
    
    @IBAction func stopRecording(sender: UIButton) {
        
        //Stop recording
        if let audioRecorder = audioRecorder{
            
            // Stop recording
            audioRecorder.stop()
            
            // Stop the counter
            timer.invalidate()
            
            //Stop all animation for record button
            stopAllAnimations(btnRecord)
            
            // desactivate the audio session
            var audioSession = AVAudioSession.sharedInstance()
            audioSession.setActive(false, error: nil)
            
        }
    }
    
    
    @IBAction func pauseRecording(sender: UIButton) {
        
        if let audioRecorder = audioRecorder{
            
            // Pause recording
            audioRecorder.pause()
            
            // Pause the timer
            timer.invalidate()
            
            //Disable pause button"
            btnPause.enabled = false
            
            //Enable resume button"
            btnResume.enabled = true
            
            //Change Recording status label
            lblRecordingStatus.text = "Record in pause"
            
            //Stop All Animation for record button & Set opacity to 0.5
            stopAllAnimations(btnRecord)
            btnRecord.alpha = 0.5
            
        }
        
    }
    
    @IBAction func resumeRecording(sender: UIButton) {
        
        if let audioRecorder = audioRecorder{
            
            // Resume recording
            audioRecorder.record()
            
            timer = NSTimer.scheduledTimerWithTimeInterval(1, target:self, selector: Selector("updateCounter"), userInfo: nil, repeats: true) //resume timer
            
            //Disable resume button
            btnResume.enabled = false
            
            //Enable pause button
            btnPause.enabled = true
            
            //Change Recording status label
            lblRecordingStatus.text = "Record in progress..."
            
            //Start flashing animation for the record button
            flashViewWithFadingTransition(btnRecord)
            
        }
    }
 
    //MARK: recorder delagated functions
    
    // Is triggered when the audio recorder finishes the recording. Perform the segue to PlaySoundsViewController
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder!, successfully flag: Bool) {
        
        if(flag){ //if record is successfull
            
            // Save the recorded audio
            recordedAudioFile = AVAudioFile(forReading: recorder.url, error: nil)
            
            // Move to the next scene aka perform segue
            // Segue to PlaySoundsViewController
            self.performSegueWithIdentifier("gotoPlaySoundsViewController", sender: recordedAudioFile)
        }
        else{
            
            // Popup an alert
            var alert = UIAlertController(title: "Error", message: "Recording fails due to an unknown error", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            
            // Reset UI to initial state
            self.viewWillAppear(false)

        }

    }
    
    //MARK: Custom functions
    
    // Return a new unique file path based on the current date/time
    func newFilePathBasedOnCurrentTime() -> NSURL!{
        let currentDateTime = NSDate()
        var formatter = NSDateFormatter()
        formatter.dateFormat = "ddMMyyyy-HHmmss"
        //TODO : change sound format
        let recordingName = "PitchPerfect_"+formatter.stringFromDate(currentDateTime)+".wav"
        let pathArray = [userDocumentFolderPath, recordingName]
        return NSURL.fileURLWithPathComponents(pathArray)
    }
    
    // Update the timer label based on counter value
    func updateCounter() {
        ++counter
        var tempCounterTxt = ""
        tempCounterTxt +=  "\(counter/60)"
        tempCounterTxt +=  ":"
        
        // add a "0" if seconds are < 10
        if ((counter%60) < 10){
            tempCounterTxt += "0"
        }
        tempCounterTxt += "\(counter%60)"
        lblTimer.text = tempCounterTxt
    }
    
    //MARK: Prepare for Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        // gotoPlaySoundsViewController Segue
        if (segue.identifier == "gotoPlaySoundsViewController"){
            let playSoundVC:PlaySoundsViewController = segue.destinationViewController as! PlaySoundsViewController
            let data = sender as! AVAudioFile?
            playSoundVC.audioFile = data
        }
    }

}
