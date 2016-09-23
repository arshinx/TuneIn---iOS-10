//
//  SearchViewController.swift
//  HalfTunes
//
//  Created by Arshin Jain.
//  Copyright (c) 2016 Arshin Jain. All rights reserved.
//

import UIKit
import MediaPlayer

class SearchViewController: UIViewController {
    
    var activeDownloads = [String: Download]()
    
    // NSURLSession object initialized with configuration
    let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
    
    // When user searches, make HTTP GET requests
    var dataTask: URLSessionDataTask?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    // Maintain Mappings
    var searchResults   = [Track]()
    
  
    // Perform / Create when needed
    lazy var tapRecognizer: UITapGestureRecognizer = {
        var recognizer = UITapGestureRecognizer(target:self, action: #selector(SearchViewController.dismissKeyboard))
        return recognizer
    }()
    
    var downloadsSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        let session       = URLSession(configuration: configuration)
        return session
    }()
  
    // MARK: View controller methods
  
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }
  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
  
    // MARK: Handling Search Results
  
    // This helper method helps parse response JSON NSData into an array of Track objects.
    func updateSearchResults(_ data: Data?) {
        searchResults.removeAll()
        do {
            if let data = data, let response = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions(rawValue:0)) as? [String: AnyObject] {
        
                // Get the results array
                if let array: AnyObject = response["results"] {
                    for trackDictonary in array as! [AnyObject] {
                        if let trackDictonary = trackDictonary as? [String: AnyObject], let previewUrl = trackDictonary["previewUrl"] as? String {
                            // Parse the search result
                            let name = trackDictonary["trackName"] as? String
                            let artist = trackDictonary["artistName"] as? String
                            searchResults.append(Track(name: name, artist: artist, previewUrl: previewUrl))
                        } else {
                            print("Not a dictionary")
                        }
                    }
                } else {
                    print("Results key not found in dictionary")
                }
            } else {
                print("JSON Error")
            }
        } catch let error as NSError {
            print("Error parsing results: \(error.localizedDescription)")
        }
    
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.setContentOffset(CGPoint.zero, animated: false)
        }
    }
    
    // Locate Track and Return Index
    func trackIndexForDownloadTask(downloadTask: URLSessionDownloadTask) -> Int? {
     
        if let url = downloadTask.originalRequest?.url?.absoluteString {
            
            for (index, track) in searchResults.enumerated() {
                
                // Return Index Value (if urls match)
                if url == track.previewUrl! {
                    return index
                }
            }
        }
        return nil
    }

  
    // MARK: Keyboard dismissal
    
    func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
  
    // MARK: Download methods
  
    // Called when the Download button for a track is tapped
    func startDownload(_ track: Track) {
        
        if let urlString = track.previewUrl, let url = URL(string: urlString) {
            
            // Initialize Download w/ url
            let download = Download(url: urlString)
            
            // Set download task
            download.downloadTask = downloadsSession.downloadTask(with: url)
            
            // start download
            download.downloadTask!.resume()
            
            // Set download tracker
            download.isDownloadng = true
            
            // Map downloads url to download in active downloads directory
            activeDownloads[download.url] = download
        }
    }
  
  // Called when the Pause button for a track is tapped
  func pauseDownload(_ track: Track) {
    // TODO
  }
  
  // Called when the Cancel button for a track is tapped
  func cancelDownload(_ track: Track) {
    // TODO
  }
  
  // Called when the Resume button for a track is tapped
  func resumeDownload(_ track: Track) {
    // TODO
  }
  
   // This method attempts to play the local file (if it exists) when the cell is tapped
  func playDownload(_ track: Track) {
    if let urlString = track.previewUrl, let url = localFilePathForUrl(urlString) {
      let moviePlayer:MPMoviePlayerViewController! = MPMoviePlayerViewController(contentURL: url)
      presentMoviePlayerViewControllerAnimated(moviePlayer)
    }
  }
  
    // MARK: Download helper methods
  
    // This method generates a permanent local file path to save a track to by appending
    // the lastPathComponent of the URL (i.e. the file name and extension of the file)
    // to the path of the app’s Documents directory.
    func localFilePathForUrl(_ previewUrl: String) -> URL? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
    
        let url = URL(string: previewUrl)
    
        if let lastPathComponent = url?.lastPathComponent {
            let fullPath = documentsPath.appendingPathComponent(lastPathComponent)
            return URL(fileURLWithPath:fullPath)
        }
        return nil
    }
  
    // This method checks if the local file exists at the path generated by localFilePathForUrl(_:)
    func localFileExistsForTrack(_ track: Track) -> Bool {
        if let urlString = track.previewUrl, let localUrl = localFilePathForUrl(urlString) {
            var isDir : ObjCBool = false
            let path = localUrl.path
            
            return FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
            
        }
        return false
    }
    
    // Return track index
    func trackIndexForDownloadTask(_ downloadTask: URLSessionDownloadTask) -> Int? {
     
        // retrieve url and unwrap when available
        if let url = downloadTask.originalRequest?.url?.absoluteString {
            
            // Retrieve all tracks with their index
            for (index, track) in searchResults.enumerated() {
                
                // if url matches desired url
                if url == track.previewUrl! {
                    return index
                }
            }
        }
        
        return nil
        
    }
    
}

// MARK: URL Session Download Delegate - Extension
extension SearchViewController: URLSessionDownloadDelegate {
    
    // Download / Play Music --
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        // Extract Request URL from Task, then Generate Permanent local file path to save (path's doc. dir.)
        if let originalURL = downloadTask.originalRequest?.url?.absoluteString,
            let destinationURL = localFilePathForUrl(originalURL) {
            
            // Log Destination URL
            print(destinationURL)
            
            // Move Downloaded file from temporary to desired location
            let fileManager = FileManager.default
            
            do {
                try fileManager.removeItem(at: destinationURL)
            } catch {
                // Non-destructive - File likely does not exist
            }
            
            do {
                try fileManager.copyItem(at: location, to: destinationURL)
            } catch let error as Error {
                print("Could not copy file to disk: \(error.localizedDescription)")
            }
        }
        
        // Remove Downloads from Active Downloads Directory
        if let url = downloadTask.originalRequest?.url?.absoluteString {
            activeDownloads[url] = nil
            
            // Locate Track and Reload Table View
            if let trackIndex = trackIndexForDownloadTask(downloadTask) {
                DispatchQueue.main.async(execute: { 
                    self.tableView.reloadRows(at: [IndexPath(row: trackIndex, section: 0)], with: .none)
                })
            }
                
        }
    }
    
    // Show/Track Download Progress --
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        // Extract url & find download in directory
        if let downloadUrl = downloadTask.originalRequest?.url?.absoluteString, let download = activeDownloads[downloadUrl] {
            
            // Calculate progress as ratio and save
            download.progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            
            // Generate readable format to display
            let totalSize = ByteCountFormatter.string(fromByteCount: totalBytesExpectedToWrite, countStyle: ByteCountFormatter.CountStyle.binary)
            
            //
        }
    }
}


// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        // Dimiss the keyboard
        dismissKeyboard()
    
        // Search bar is not empty
        if !searchBar.text!.isEmpty {
            
            // Cancel data tasks should they be available
            if dataTask != nil {
                
                dataTask?.cancel()
            }
            
            // Enable Activity indicator
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            // Verify whether string query is properly encoded
            let expectedCharSet = CharacterSet.urlQueryAllowed
            let searchTerm = searchBar.text!.addingPercentEncoding(withAllowedCharacters: expectedCharSet)!
            
            // Create a url object for iTunes Search API
            let url = URL(string: "https://itunes.apple.com/search?media=music&entity=song&term=\(searchTerm)")
            
            // Handle HTTP GET request
            dataTask = defaultSession.dataTask(with: url!, completionHandler: {
                
                data, response, error in
                
                // Hide activity indicator, UI update on main thread!
                DispatchQueue.main.async(execute: { 
                    
                    // Hide activity indicator
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                })
                
                // If request is successful, parse response and update data in table view
                if let error = error {
                    
                    // Log Error
                    print(error.localizedDescription)
                    
                } else if let httpResponse = response as? HTTPURLResponse {
                    
                    // If request is successful (200 : OK)
                    if httpResponse.statusCode == 200 {
                        
                        // Update Search Results with Data
                        self.updateSearchResults(data)
                    }
                }
            })
            
            // Start Data Task
            dataTask?.resume()
        }
  }
    
  func position(for bar: UIBarPositioning) -> UIBarPosition {
    return .topAttached
  }
    
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    view.addGestureRecognizer(tapRecognizer)
  }
    
  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    view.removeGestureRecognizer(tapRecognizer)
  }
}

// MARK: TrackCellDelegate

extension SearchViewController: TrackCellDelegate {
  func pauseTapped(_ cell: TrackCell) {
    if let indexPath = tableView.indexPath(for: cell) {
      let track = searchResults[(indexPath as NSIndexPath).row]
      pauseDownload(track)
      tableView.reloadRows(at: [IndexPath(row: (indexPath as NSIndexPath).row, section: 0)], with: .none)
    }
  }
  
  func resumeTapped(_ cell: TrackCell) {
    if let indexPath = tableView.indexPath(for: cell) {
      let track = searchResults[(indexPath as NSIndexPath).row]
      resumeDownload(track)
      tableView.reloadRows(at: [IndexPath(row: (indexPath as NSIndexPath).row, section: 0)], with: .none)
    }
  }
  
  func cancelTapped(_ cell: TrackCell) {
    if let indexPath = tableView.indexPath(for: cell) {
      let track = searchResults[(indexPath as NSIndexPath).row]
      cancelDownload(track)
      tableView.reloadRows(at: [IndexPath(row: (indexPath as NSIndexPath).row, section: 0)], with: .none)
    }
  }
  
  func downloadTapped(_ cell: TrackCell) {
    if let indexPath = tableView.indexPath(for: cell) {
      let track = searchResults[(indexPath as NSIndexPath).row]
      startDownload(track)
      tableView.reloadRows(at: [IndexPath(row: (indexPath as NSIndexPath).row, section: 0)], with: .none)
    }
  }
}

// MARK: UITableViewDataSource

extension SearchViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return searchResults.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as!TrackCell
    
    // Delegate cell button tap events to this view controller
    cell.delegate = self
    
    let track = searchResults[(indexPath as NSIndexPath).row]
    
    // Configure title and artist labels
    cell.titleLabel.text = track.name
    cell.artistLabel.text = track.artist

    // If the track is already downloaded, enable cell selection and hide the Download button
    let downloaded = localFileExistsForTrack(track)
    cell.selectionStyle = downloaded ? UITableViewCellSelectionStyle.gray : UITableViewCellSelectionStyle.none
    cell.downloadButton.isHidden = downloaded
    
    return cell
  }
}

// MARK: UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 62.0
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let track = searchResults[(indexPath as NSIndexPath).row]
    if localFileExistsForTrack(track) {
      playDownload(track)
    }
    tableView.deselectRow(at: indexPath, animated: true)
  }
}
