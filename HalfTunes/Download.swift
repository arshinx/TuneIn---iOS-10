//
//  Download.swift
//  TuneIn
//
//  Created by Arshin Jain on 9/20/16.
//  Copyright © 2016 Arshin. All rights reserved.
//
import UIKit

class Download: NSObject {
    
    var url: String
    var isDownloadng = false
    var progress: Float = 0.0
    
    var downloadTask: URLSessionDownloadTask?
    var resumeData: NSData?
    
    init(url: String) {
        self.url = url
    }
    
}
