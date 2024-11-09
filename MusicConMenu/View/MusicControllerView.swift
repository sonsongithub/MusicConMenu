//
//  MusicControllerView.swift
//  MusicMenu
//
//  Created by Yuichi Yoshida on 2024/11/02.
//

import Foundation
import Cocoa

class MusicControllerView : NSView {
    
    @IBOutlet var titleLabel: NSTextField?
    @IBOutlet var artistLabel: NSTextField?
    @IBOutlet var playlistLabel: NSTextField?
    @IBOutlet var playButton: NSButton?
    @IBOutlet var forwardButton: NSButton?
    @IBOutlet var backwardButton: NSButton?
    @IBOutlet var volumeSlider: NSSlider?
    @IBOutlet var artworkImageView: NSImageView?
    @IBOutlet var volumeImage: NSImageView?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let center = DistributedNotificationCenter.default()
        center.addObserver(self, selector: #selector(receiveNotification(_:)), name: NSNotification.Name("com.apple.Music.playerInfo"), object: nil)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        let center = DistributedNotificationCenter.default()
        center.addObserver(self, selector: #selector(receiveNotification(_:)), name: NSNotification.Name("com.apple.Music.playerInfo"), object: nil)
    }
    
    static func create(frame frameRect: NSRect ) -> MusicControllerView? {
        var topLevelObjects: NSArray? = nil
        Bundle.main.loadNibNamed("MusicControllerView", owner: self, topLevelObjects: &topLevelObjects)
        guard let view = topLevelObjects?.first(where: { $0 is NSView }) as? MusicControllerView else {
            return nil
        }
        view.frame = frameRect
        view.autoresizingMask = [.width, .height]
        return view
    }
    
    @IBAction func playButtonClicked(_ sender: NSButton) {
        print("Play button clicked")
        if let musicApp = SBApplication.musicApp {
            musicApp.playpause?()
        }
        self.setNeedsDisplay(.zero)
    }
    
    @IBAction func forwardButtonClicked(_ sender: NSButton) {
        print("Forward button clicked")
        if let musicApp = SBApplication.musicApp {
            musicApp.nextTrack?()
        }
        self.setNeedsDisplay(.zero)
    }
    
    @IBAction func backwardButtonClicked(_ sender: NSButton) {
        print("Backward button clicked")
        if let musicApp = SBApplication.musicApp {
            musicApp.previousTrack?()
        }
        self.setNeedsDisplay(.zero)
    }
    
    @IBAction func volumeSliderChanged(_ sender: NSSlider) {
        print("Volume slider changed")
        
        if let musicApp = SBApplication.musicApp {
            if let slider = self.volumeSlider {
                musicApp.setSoundVolume?(slider.integerValue)
            }
        }
        self.setNeedsDisplay(.zero)
    }
    
    func update() {
        Task {
            if let musicApp = SBApplication.musicApp {
                guard let currentVolume = musicApp.soundVolume else { return }
                guard let currentTrack = musicApp.currentTrack else { return }
                guard let songTitle = currentTrack.name else { return }
                guard let artist = currentTrack.artist else { return }
                guard let currentPlaylist = musicApp.currentPlaylist else { return }
                guard let playlistName = currentPlaylist.name else { return }
                guard let state = musicApp.playerState else { return }
                let artwork = currentTrack.artworks?().first
                DispatchQueue.main.async {
                    if let slider = self.volumeSlider {
                        slider.doubleValue = Double(currentVolume)
                        self.volumeImage?.updateSoundVolume(with: slider)
                    }
                    if let titleLabel = self.titleLabel {
                        titleLabel.stringValue = String(songTitle)
                    }
                    if let artistLabel = self.artistLabel {
                        artistLabel.stringValue = String(artist)
                    }
                    if let playlistLabel = self.playlistLabel {
                        playlistLabel.stringValue = String(playlistName)
                    }
                    switch state {
                    case .playing:
                        self.playButton?.image = NSImage.init(systemSymbolName: "pause.fill", accessibilityDescription: nil)
                    case .paused:
                        self.playButton?.image = NSImage.init(systemSymbolName: "play.fill", accessibilityDescription: nil)
                    default:
                        break
                    }
                    self.artworkImageView?.image = artwork?.data ?? NSImage(systemSymbolName: "photo.artframe", accessibilityDescription: nil)
                }
            }
        }
    }
    
    @objc func receiveNotification(_ notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let message = userInfo["Player State"] as? String {
                if message == "Playing" {
                    self.update()
                }
                if message == "Paused" {
                    self.update()
                }
            }
        }
    }
    
    deinit {
        print("MusicControllerView - Deinit")
        let center = DistributedNotificationCenter.default()
        center.removeObserver(self)
    }
}
