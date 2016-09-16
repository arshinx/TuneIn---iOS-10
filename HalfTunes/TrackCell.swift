//
//  TrackCell.swift
//  HalfTunes
//
//  Created by Arshin Jain.
//  Copyright (c) 2016 Arshin Jain. All rights reserved.
//

import UIKit

protocol TrackCellDelegate {
  func pauseTapped(cell: TrackCell)
  func resumeTapped(cell: TrackCell)
  func cancelTapped(cell: TrackCell)
  func downloadTapped(cell: TrackCell)
}

class TrackCell: UITableViewCell {
  
  var delegate: TrackCellDelegate?
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var artistLabel: UILabel!
  @IBOutlet weak var progressView: UIProgressView!
  @IBOutlet weak var progressLabel: UILabel!
  @IBOutlet weak var pauseButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var downloadButton: UIButton!
  
  @IBAction func pauseOrResumeTapped(sender: AnyObject) {
    if(pauseButton.titleLabel!.text == "Pause") {
      delegate?.pauseTapped(self)
    } else {
      delegate?.resumeTapped(self)
    }
  }
  
  @IBAction func cancelTapped(sender: AnyObject) {
    delegate?.cancelTapped(self)
  }
  
  @IBAction func downloadTapped(sender: AnyObject) {
    delegate?.downloadTapped(self)
  }
}
