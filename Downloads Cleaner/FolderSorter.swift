//
//  Sorter.swift
//  Downloads Cleaner
//
//  Created by Braden Schneider on 24/5/25.
//

import Foundation
import UniformTypeIdentifiers

let installerTypes = ["dmg", "pkg", "msi", "exe"]
let documentTypes = ["pdf", "doc", "docx", "rtf", "txt", "odt", "pages", "csv", "xls", "xlsx", "ods", "ppt", "pptx", "odp", "epub", "mobi"]

let catagories = ["Other", "Images", "Text Files", "Installers", "Scripts", "Audio Files", "Videos", "Archives", "Documents", "Applications"]

struct FolderSorter {
    static func getBookmark() -> URL?
    {
        do {
            var isStale = false
            
            guard let bookmarkData = UserDefaults.standard.data(forKey: "SelectedFolderBookmark") else {
                print("Couldn't find bookmark 'SelectedFolderBookmark'")
                return nil
            }
            
            let url = try URL.init(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                print("Bookmark is stale!")
            }
            
            return url
        } catch {
            print("Ran into a problem while loading the bookmark")
            return nil
        }
    }
    
    static func sortFolderContents(
        makeOther: Bool,
        otherIncludesFolders: Bool,
        resort: Bool, // Not implimented
        deleteInstallers: Bool // Not implimented
    ) -> Bool {
        let fileManager = FileManager.default
        
        do {
            guard let url = getBookmark() else {
                print("Couldn't load bookmark")
                return false
            }
            
            if (url.startAccessingSecurityScopedResource()) {
                // Get folder contents
                var items = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                // If resort folders is enabled, iterate through the DC folders and move their items back to the main downloads folder
                if resort {
                    for item in items {
                        var isDirectory: ObjCBool = false
                        
                        // Check if file exists, is a folder, and is a DC folder
                        if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory) {
                            if catagories.contains(item.lastPathComponent) &&  isDirectory.boolValue {
                                let sortedFiles = try fileManager.contentsOfDirectory(at: item, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                                
                                // Move all files in this DC folder to the downloads folder
                                for sortedFile in sortedFiles {
                                    let destinationPath = url.appendingPathComponent(sortedFile.lastPathComponent)
                                    try fileManager.moveItem(at: sortedFile, to: destinationPath)
                                }
                            }
                        }
                    }
                    
                    // Get the new folder contents
                    items = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                }
                
                // Iterate through the contents
                for item in items {
                    var isDirectory: ObjCBool = false
                    
                    if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory) {
                        let catagory: Int // Catagory is given as an index of the catagories array
                        
                        // Directories go to other or get ignored
                        if isDirectory.boolValue {
                            if item.pathExtension == "app" // App bundles get marked as directories, so handle that here
                            {
                                catagory = 9
                            }
                            else if makeOther && otherIncludesFolders && !catagories.contains(item.lastPathComponent) {
                                catagory = 0
                            }
                            else {
                                catagory = -1 // catagory -1 is ignored
                            }
                        }
                        else {
                            let fileExtension = item.pathExtension
                            let resourceValues = try item.resourceValues(forKeys: [.contentTypeKey])
                            
                            // Check the file type, and put in catagory
                            if let contentType = resourceValues.contentType {
                                print("Found item '\(item.lastPathComponent)'")
                                print("contentType is '\(contentType.identifier)'")
                                if contentType.conforms(to: .image) {
                                    catagory = 1
                                }
                                else if contentType.conforms(to: .text) {
                                    catagory = 2
                                }
                                else if installerTypes.contains(fileExtension) {
                                    if (deleteInstallers)
                                    {
                                        catagory = -1
                                        try fileManager.removeItem(at: item)
                                    }
                                    else {
                                        catagory = 3
                                    }
                                }
                                else if contentType.conforms(to: .script) {
                                    catagory = 4
                                }
                                else if contentType.conforms(to: .audio) {
                                    catagory = 5
                                }
                                else if contentType.conforms(to: .audiovisualContent) {
                                    catagory = 6
                                }
                                else if contentType.conforms(to: .archive) {
                                    catagory = 7
                                }
                                else if documentTypes.contains(fileExtension) {
                                    catagory = 8
                                }
                                else if makeOther {
                                    catagory = 0
                                }
                                else {
                                    catagory = -1
                                }
                            }
                            else if makeOther {
                                catagory = 0
                            }
                            else {
                                catagory = -1
                            }
                        }
                        
                        // If the file should be ignored, it will not be moved anywhere
                        if catagory != -1 {
                            let catagoryFolder = url.appendingPathComponent(catagories[catagory])
                            if !fileManager.fileExists(atPath: catagoryFolder.path) {
                                try fileManager.createDirectory(at: catagoryFolder, withIntermediateDirectories: false)
                            }
                            
                            let destinationPath = catagoryFolder.appendingPathComponent(item.lastPathComponent)
                            try fileManager.moveItem(at: item, to: destinationPath)
                        }
                    }
                }
                
                url.stopAccessingSecurityScopedResource()
            }
            else {
                print("Couldn't access security scoped resource")
                return false
            }
        } catch {
            print("Something went wrong, see below for the error:")
            print(error)
            return false
        }
        
        return true
    }
    
    static func emptyFolder() -> Bool {
        let fileManager = FileManager.default
        
        do {
            guard let url = getBookmark() else {
                print("Couldn't load bookmark")
                return false
            }
            
            if (url.startAccessingSecurityScopedResource())
            {
                let items = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                
                // Delete all files in the directory
                for item in items {
                    print("Removing '\(item.lastPathComponent)'")
                    try fileManager.removeItem(at: item)
                }
                
                url.stopAccessingSecurityScopedResource()
            }
            else {
                print("Couldn't access security scoped resource")
                return false
            }
        } catch {
            print("Something went wrong, see below for the error:")
            print(error)
            return false
        }
        
        return true
    }
}
