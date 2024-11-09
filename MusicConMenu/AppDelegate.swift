//
//  AppDelegate.swift
//  MusicConMenu
//
//  Created by Yuichi Yoshida on 2024/11/04.
//

import Cocoa
import Foundation

extension NSImageView {
    func updateSoundVolume(with slider: NSSlider) {
        if slider.integerValue == 0 {
            self.image = NSImage.init(systemSymbolName: "speaker", accessibilityDescription: nil)
        } else if slider.integerValue < 33 {
            self.image = NSImage.init(systemSymbolName: "speaker.wave.1", accessibilityDescription: nil)
        } else if slider.integerValue < 66 {
            self.image = NSImage.init(systemSymbolName: "speaker.wave.2", accessibilityDescription: nil)
        } else {
            self.image = NSImage.init(systemSymbolName: "speaker.wave.3", accessibilityDescription: nil)
        }
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let mainMenu = NSMenu()
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let airplayMenu = NSMenu()
    var isMusicAppRunning = false
    
    var airplayDeviceNames: [AirPlayDeviceInfo] = []
    var playlists: [String] = []
    
    var listIsUpdated = false
    var isOpened = false
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        if let button = self.statusItem.button {
            button.image = NSImage.init(systemSymbolName: "music.note.house.fill", accessibilityDescription: nil)
        }
        self.statusItem.menu = mainMenu
        mainMenu.delegate = self
        self.isMusicAppRunning = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.apple.Music" }
        
        if self.isMusicAppRunning {
            self.airplayDeviceNames = SBApplication.getCurrentAirPlayDevices()
            self.playlists = SBApplication.getCurrentPlaylistNames()
        }
        
        // timer check something on background
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            guard !self.isOpened else { return }
            guard NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == "com.apple.Music" }) else { return }

            Task {
                let tmpAirplayDeviceNames = SBApplication.getCurrentAirPlayDevices()
                let tmpPlaylists = SBApplication.getCurrentPlaylistNames()
                DispatchQueue.main.async {
                    if Set(tmpAirplayDeviceNames) != Set(self.airplayDeviceNames) {
                        self.airplayDeviceNames = tmpAirplayDeviceNames
                        self.listIsUpdated = true
                    }
                    if Set(tmpPlaylists) != Set(self.playlists) {
                        self.playlists = tmpPlaylists
                        self.listIsUpdated = true
                    }
                }
            }
        }
                
        reloadMenu()
    }
    
    func reloadMenu() {
        print(#function)
        
        mainMenu.removeAllItems()
        
        let menuItem = NSMenuItem()
        
        
        menuItem.title = "Music"
        
        guard self.isMusicAppRunning else {
            let item = NSMenuItem(title: "Run Music.app", action: #selector(startMusic(_:)), keyEquivalent: "")
            mainMenu.addItem(item)
            return
        }
        
        let view = MusicControllerView.create(frame: NSRect(x: 0, y: 0, width: 280, height: 180))
        menuItem.view = view
        view?.update()
        
        mainMenu.addItem(menuItem)
        do {
            let subMenu = NSMenu()
            subMenu.title = "Playlists"
            let subMenuItem = NSMenuItem()
            subMenuItem.title = "Playlists"
            subMenuItem.submenu = subMenu
            self.playlists.forEach({ subMenu.addItem(withTitle: $0, action: #selector(selectPlaylist(_:)), keyEquivalent: "") })
            mainMenu.addItem(subMenuItem)
        }
        do {
            self.airplayMenu.title = "AirPlay"
            let subMenuItem = NSMenuItem()
            subMenuItem.title = "AirPlay"
            subMenuItem.submenu = airplayMenu
            airplayMenu.removeAllItems()
            
            self.airplayDeviceNames.forEach { info in
                let item = NSMenuItem(title: String(info.name), action: nil, keyEquivalent: "")
                let view = AirPlayDeviceView.create(frame: NSRect(x: 0, y: 0, width: 300, height: 50), name: info.name)
                view?.icon?.image = info.kind.icon
                item.view = view
                view?.deviceNameLabel?.stringValue = String(info.name)
                airplayMenu.addItem(item)
            }
            mainMenu.addItem(subMenuItem)
        }
        do {
            
            mainMenu.addItem(NSMenuItem.separator())
            let item = NSMenuItem(title: "Quit", action: #selector(quitClicked(_:)), keyEquivalent: "q")
            mainMenu.addItem(item)
        }
    }
    
    @IBAction func startMusic(_ sender: NSMenuItem) {
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/System/Applications/Music.app/"), configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
    }
    
    @IBAction func selectPlaylist(_ sender: NSMenuItem) {
        guard let musicApp = SBApplication.musicApp else { return }
        guard let playlists = musicApp.playlists?() else { return }
        guard let target = playlists.first(where: { String($0.name ?? "")  == sender.title }) else { return }
        target.play()
    }
    
    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    // MARK: - NSApplicationDelegate

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    // MARK: - NSMenuDelegate
    
    func menuWillOpen(_ menu: NSMenu) {
        self.isOpened = true
        let running = NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == "com.apple.Music" }
        print(running)

        var dirty = false
        
        print("self.listIsUpdated - \(self.listIsUpdated)")
        print("self.isMusicAppRunning - \(self.isMusicAppRunning)")
        
        dirty = self.listIsUpdated || (running != self.isMusicAppRunning)
        self.listIsUpdated = false
        self.isMusicAppRunning = running
        if dirty {
            self.reloadMenu()
        }
        print("dirty - \(dirty)")
    }
    
    func menuDidClose(_ menu: NSMenu) {
        self.isOpened = false
    }
}


