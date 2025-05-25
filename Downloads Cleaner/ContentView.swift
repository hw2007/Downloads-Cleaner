//
//  ContentView.swift
//  Downloads Cleaner
//
//  Created by Braden Schneider on 24/5/25.
//

import SwiftUI
import ConfettiSwiftUI
import AppKit
import AudioToolbox

let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

struct ContentView: View {
    @AppStorage("makeOther") private var makeOther = true
    @AppStorage("otherIncludesFolders") private var otherIncludesFolders = true
    @AppStorage("resort") private var resort = false
    @AppStorage("deleteInstallers") private var deleteInstallers = false
    @AppStorage("selectedFolderString") private var folderPath = "No folder chosen yet"
    
    @State private var trigger = 0
    @State private var status = "Downloads Cleaner v" + version!
    
    @State private var showAlert = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Clean Options:")
            Toggle("Make an 'Other' folder", isOn: $makeOther)
            Toggle("Move user-created folders to the 'Other' folder", isOn: $otherIncludesFolders)
                .disabled(!makeOther)
            Toggle("Resort folders created by Downloads Cleaner", isOn: $resort)
            Toggle("Delete app installers (.dmg, .pkg, .exe, .msi)", isOn: $deleteInstallers)
            
            Divider()
            
            Text("Downloads Folder Location:")
            HStack {
                Button("Choose") {
                    chooseFolder()
                }
                Text("Current Location: " + folderPath).foregroundStyle(.gray)
            }
            
            Divider()
            
            HStack {
                Button {
                    clean()
                } label: {
                    Label("Clean!", systemImage: "wand.and.sparkles.inverse")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: [])
                .padding(.trailing)
                
                Spacer()
                    .frame(width: 0, height: 0)
                    .confettiCannon(
                        trigger: $trigger,
                        num: 20,
                        rainHeight: 800,
                        openingAngle: Angle(degrees: 0),
                        closingAngle: Angle(degrees: 180),
                        radius: 150
                    )
                
                Button {
                    showAlert = true
                } label: {
                    Label("Empty", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                .padding(.leading)
                .alert("Warning", isPresented: $showAlert) {
                    Button("Cancel", role: .cancel) {
                        
                    }
                    Button("Proceed", role: .destructive) {
                        empty()
                    }
                    } message: {
                        Text("Emptying your downloads folder will delete all of its contents. Are you sure you want to proceed?")
                    }
            }
            .frame(maxWidth: .infinity)
            .padding([.bottom, .top], 8)
            
            Text(status)
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
    
    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Select your downloads folder"
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                folderPath = url.path
                
                // Create a "bookmark" to tell macOS to let our app access this folder in the future
                do {
                    let bookmark = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                    UserDefaults.standard.set(bookmark, forKey: "SelectedFolderBookmark")
                    folderPath = url.path
                } catch {
                    print("Failed to create security bookmark, see below for error:")
                    print(error)
                }
            }
        }
    }
    
    func clean() {
        status = "Working on it..."
        
        // Sort the folder in a thread
        DispatchQueue.global(qos: .userInitiated).async {
            
            let result = FolderSorter.sortFolderContents(
                makeOther: makeOther,
                otherIncludesFolders: otherIncludesFolders,
                resort: resort,
                deleteInstallers: deleteInstallers
            )
            
            if result {
                NSSound(named: "Glass")?.play()
                trigger += 1
                status = "Your downloads folder has been cleaned!"
            }
            else {
                NSSound(named: "Hero")?.play()
                status = "Something went wrong. Does the chosen folder still exist?"
            }
        }
    }
    
    func empty() {
        status = "Working on it..."
        
        // Sort the folder in a thread
        DispatchQueue.global(qos: .userInitiated).async {
            
            let result = FolderSorter.emptyFolder()
            
            if result {
                AudioServicesPlaySystemSound(0x10)
                trigger += 1
                status = "Your downloads folder has been emptied!"
            }
            else {
                NSSound(named: "Hero")?.play()
                status = "Something went wrong. Does the chosen folder still exist?"
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 450, height: 284)
}
