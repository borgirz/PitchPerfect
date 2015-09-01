//
//  RecordedAudio.swift
//  PitchPerfect
//
//  Created by Nicolas Jasmes on 01/09/15.
//  Copyright (c) 2015 Nicolas Jasmes. All rights reserved.
//


import AVFoundation

final class RecordedAudio: NSObject {
    
    // MARK: Properties
    // ****************
    
    var filePathUrl: NSURL
    var fileName: String?
    var ext: String?
    
    // initialiser
    init(filePathUrl: NSURL, fileName: String?, ext: String?) {

        self.filePathUrl = filePathUrl
        self.fileName = fileName
        self.ext = ext
    }
    
    // Convenience initialiser : Set fileName & Ext with information extracted from path
    convenience init(filePathUrl: NSURL){
        
        self.init(filePathUrl: filePathUrl, fileName: filePathUrl.lastPathComponent, ext: filePathUrl.pathExtension)
    }
    
    // Return the object as an AVAudioFile
    func asAVAudioFile() -> AVAudioFile{
        
        return AVAudioFile(forReading: filePathUrl, error: nil)
    }
}

// EOF
