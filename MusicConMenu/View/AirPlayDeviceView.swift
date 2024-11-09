//
//  AirPlayDeviceView.swift
//  MusicMenu
//
//  Created by Yuichi Yoshida on 2024/11/04.
//

import Cocoa

class AirPlayDeviceView : NSView {
    var name: String = ""
    
    @IBOutlet var deviceNameLabel: NSTextField?
    @IBOutlet var deviceVolumeSlider: NSSlider?
    @IBOutlet var enableButton: NSButton?
    @IBOutlet var icon: NSImageView?
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
    
    static func create(frame frameRect: NSRect, name: String) -> AirPlayDeviceView? {
        var topLevelObjects: NSArray? = nil
        Bundle.main.loadNibNamed("AirPlayDeviceView", owner: self, topLevelObjects: &topLevelObjects)
        guard let view = topLevelObjects?.first(where: { $0 is NSView }) as? AirPlayDeviceView else {
            return nil
        }
        view.name = name
        view.frame = frameRect
        view.autoresizingMask = [.width, .height]
        
        view.update()
        return view
    }
    
    func update() {
        Task {
            guard let musicApp = SBApplication.musicApp else { return }
            guard let device = musicApp.AirPlayDevices?().first(where: { String($0.name ?? "") == self.name }) else { return }
            
            DispatchQueue.main.async {
                guard let device_select = device.selected else { return }
                
                if let stateButton = self.enableButton {
                    stateButton.state = device_select ? .on : .off
                }
                if let stateSlider = self.deviceVolumeSlider {
                    stateSlider.isHidden = !device_select
                    self.volumeImage?.isHidden = !device_select
                    stateSlider.integerValue = device.soundVolume ?? 0
                    
                    if stateSlider.integerValue == 0 {
                        self.volumeImage?.image = NSImage.init(systemSymbolName: "volume", accessibilityDescription: nil)
                    } else if stateSlider.integerValue < 33 {
                        self.volumeImage?.image = NSImage.init(systemSymbolName: "volume.1", accessibilityDescription: nil)
                    } else if stateSlider.integerValue < 66 {
                        self.volumeImage?.image = NSImage.init(systemSymbolName: "volume.2", accessibilityDescription: nil)
                    } else {
                        self.volumeImage?.image = NSImage.init(systemSymbolName: "volume.3", accessibilityDescription: nil)
                    }
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
    
    @IBAction func enableButtonClicked(_ sender: NSButton) {
        guard let musicApp = SBApplication.musicApp else { return }
        guard let device = musicApp.AirPlayDevices?().first(where: { String($0.name ?? "") == self.name }) else { return }
        device.setSelected?((sender.state == .on))
    }
    
    @IBAction func volumeSliderChanged(_ sender: NSSlider) {
        guard let musicApp = SBApplication.musicApp else { return }
        guard let device = musicApp.AirPlayDevices?().first(where: { String($0.name ?? "") == self.name }) else { return }
        device.setSoundVolume?(sender.integerValue)
        
        if sender.integerValue == 0 {
            self.volumeImage?.image = NSImage.init(systemSymbolName: "volume", accessibilityDescription: nil)
        } else if sender.integerValue < 33 {
            self.volumeImage?.image = NSImage.init(systemSymbolName: "volume.1", accessibilityDescription: nil)
        } else if sender.integerValue < 66 {
            self.volumeImage?.image = NSImage.init(systemSymbolName: "volume.2", accessibilityDescription: nil)
        } else {
            self.volumeImage?.image = NSImage.init(systemSymbolName: "volume.3", accessibilityDescription: nil)
        }
    }
}
