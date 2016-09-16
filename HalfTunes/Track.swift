//
//  Track.swift
//  HalfTunes
//
//  Created by Arshin Jain.
//  Copyright (c) 2016 Arshin Jain. All rights reserved.
//

class Track {
  var name: String?
  var artist: String?
  var previewUrl: String?
  
  init(name: String?, artist: String?, previewUrl: String?) {
    self.name = name
    self.artist = artist
    self.previewUrl = previewUrl
  }
}
