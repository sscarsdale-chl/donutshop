//
//  ContentView.swift
//  Donut Shop
//
//  Created by Shawn Scarsdale on 4/7/25.
//

import SwiftUI
import Foundation

// Necessary for AdobeHtmlFile and FormatUtils
// Note: For modular apps, we might need proper imports, but for now we assume these are in the same target

struct ContentView: View {
    
    @State private var selectedFolderURL: URL?
    @State private var htmlFiles: [AdobeHtmlFile] = [] {
        didSet {
            // Update step1Complete whenever htmlFiles changes
            step1Complete = selectedFolderURL != nil && !htmlFiles.isEmpty
        }
    }
    
    @State private var step1Complete: Bool = false
    @State private var step2Complete: Bool = false
    @State private var isTargeted: Bool = false

    // TODO: MAKE THE CLICKTAG TIED TO AN INPUT FIELD, PUT THE API KEY IN USERSTORAGE
    @State private var clickTagUrl: String = ""
    @State private var tinyPngApiKey: String = UserDefaults.standard.string(forKey: "tinyPngApiKey") ?? ""
    
    @State private var isSearching = false
    @State private var isFolderPickerPresented = false
    @State private var isSettingsPresented = false
    
    @State private var errorMessage: String? = ""
    @State private var statusMessage: String? = ""
    
    var body: some View {
        VStack {
            
            // HEADER
            HStack {
                Text("Donut Shop")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .padding()
                
                
                Spacer()
                
                if isSearching {
                    ProgressView("Searching for HTML files...")
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                        .font(.headline)
                        .padding()
                }

                if let status = statusMessage {
                    Text(status)
                        .foregroundColor(.dsDarkGray)
                        .fontWeight(.bold)
                        .font(.headline)
                        .padding()
                }
                
                Button(action: {
                    isSettingsPresented = true
                }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.dsPrimaryText)
                }
                .buttonStyle(PlainButtonStyle())
                .padding()
                .sheet(isPresented: $isSettingsPresented) {
                    SettingsView(tinyPngApiKey: $tinyPngApiKey)
                }
            }
            .background(.dsLightGray)
            .cornerRadius(10)

            // STEP 1
            HStack {

                ZStack {
                    Circle()
                        .fill(step1Complete ? Color.green : Color.black)
                        .frame(width: 32, height: 32)
                    Text("1")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .padding()
                
                if step1Complete, let folderURL = selectedFolderURL {
                    HStack{
                        Text("Folder: \(folderURL.path)")
                            .fontWeight(.bold)
                            .font(.headline)
                        Text("AdobeHTML Files: \(htmlFiles.count)")
                            .fontWeight(.bold)
                            .font(.headline)
                    }

                } else {
                    Text("Press 'Select Folder' or drag and drop a folder here")
                        .fontWeight(.bold)
                        .font(.headline)
                }
                
                Spacer()
                
                Button("Select Folder") {
                    htmlFiles.removeAll()
                    errorMessage = ""
                    statusMessage = ""
                    selectedFolderURL = nil
                    step1Complete = false
                    step2Complete = false
                    isFolderPickerPresented = true
                }
                .padding()
                .fileImporter(
                    isPresented: $isFolderPickerPresented,
                    allowedContentTypes: [.folder],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            print("Selected folder URL: \(url.path)")
                            // Start accessing the security-scoped resource
                            if url.startAccessingSecurityScopedResource() {
                                selectedFolderURL = url
                                findHTMLFiles(in: url)
                                // Don't forget to stop accessing the resource when done
                                url.stopAccessingSecurityScopedResource()
                            } else {
                                errorMessage = "Could not access the selected folder"
                            }
                        }
                    case .failure(let error):
                        errorMessage = "Error selecting folder: \(error.localizedDescription)"
                    }
                }

            }
            .background(.dsLightGray)
            .cornerRadius(10)
            .overlay(
                Group {
                    if isTargeted {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue, lineWidth: 3)
                            .background(Color.blue.opacity(0.1).cornerRadius(10))
                            .overlay(
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                    .opacity(0.8)
                            )
                    }
                }
            )
            .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
                guard let provider = providers.first else { return false }
                
                provider.loadObject(ofClass: URL.self) { reading, error in
                    DispatchQueue.main.async {
                        if let url = reading, url.hasDirectoryPath {
                            // Reset current state
                            htmlFiles.removeAll()
                            errorMessage = ""
                            statusMessage = ""
                            selectedFolderURL = nil
                            step1Complete = false
                            step2Complete = false
                            
                            // Process the dropped folder
                            selectedFolderURL = url
                            findHTMLFiles(in: url)
                        } else if let error = error {
                            errorMessage = "Drop error: \(error.localizedDescription)"
                        } else {
                            errorMessage = "Dropped item is not a folder"
                        }
                    }
                }
                return true
            }
            
            // STEP 2
            if (step1Complete) {
                ClickTagCell(clickTagUrl: $clickTagUrl, step2Complete: $step2Complete)
            }
            
            // FILES FOR CONVERSION
            if (step2Complete) {
                
                VStack {
                    HStack{
                        Text("Files for Conversion:")
                            .foregroundColor(.dsPrimaryText)
                            .fontWeight(.bold)
                            .font(.headline)
                        
                        Spacer()
                    }
                    .padding()

                    
                    List(htmlFiles, id: \.self) { file in
                        // File To Convert Cell
                        HStack {
                            VStack {
                                HStack {
                                    Text("Filename: \(file.fileName)")
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                HStack {
                                    Text("Width: \(file.width)")
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Height: \(file.height)")
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                
                            }
                            .padding()
                            
                            Spacer()
                            
                            // Convert button / Checkmark
                            VStack {
                                if file.isConverted {
                                    // make the image bigger
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.system(size: 24))
                                } else {
                                    Button("Convert") {
                                        if tinyPngApiKey.isEmpty {
                                            errorMessage = "TinyPNG API key not configured"
                                        } else {
                                            errorMessage = ""
                                            do {
                                                try overwriteFile(file: file)
                                            } catch {
                                                errorMessage = "Error transforming file: \(error.localizedDescription)"
                                            }
                                            
                                        }

                                    }
                                }
                            }
                            .padding()
                            
                        }
                        .background(file.isConverted ? Color.green : .dsLightGray)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(file.isConverted ? Color.green : .white, lineWidth: 2)
                        )
                        
                        

                        
                    } // END LIST
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    
                    
                } // END SECTION
                .background(.dsLightGray)
                .cornerRadius(10)


            } // step2Complete conditional end
            
            Spacer()
        }
        .padding()
    }
    
    
    // UTILITY FUNCTIONS
    
    private func handleFolderSelection(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                print("Selected folder URL: \(url.path)")
                // Start accessing the security-scoped resource
                if url.startAccessingSecurityScopedResource() {
                    selectedFolderURL = url
                    findHTMLFiles(in: url)
                    // Don't forget to stop accessing the resource when done
                    url.stopAccessingSecurityScopedResource()
                } else {
                    errorMessage = "Could not access the selected folder"
                }
            }
        case .failure(let error):
            errorMessage = "Error selecting folder: \(error.localizedDescription)"
        }
    }
    
    
    private func findHTMLFiles(in directory: URL) {
        isSearching = true
        htmlFiles.removeAll()
        errorMessage = nil
        
        // step1Complete will be updated after we find HTML files
        step1Complete = false
        
        print("Starting search in directory: \(directory.path)")
        
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        
        if enumerator == nil {
            errorMessage = "Could not create directory enumerator"
            isSearching = false
            return
        }
        
        var fileCount = 0
        while let url = enumerator?.nextObject() as? URL {
            fileCount += 1
            if url.pathExtension.lowercased() == "html" {
                if let content = try? String(contentsOf: url, encoding: .utf8) {
                    if content.contains("All tokens are represented by") || content.contains("Donut Shop") {
                        let width = FormatUtils.getWidth(content)
                        let height = FormatUtils.getHeight(content)
                        let compositionId = FormatUtils.getCompositionId(content)
                        let fileName = url.lastPathComponent.replacingOccurrences(of: ".html", with: "")
                        
                        // Find images in the same directory
                        let directory = url.deletingLastPathComponent()
                        var images: [URL] = []
                        if let dirEnumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
                            while let imageUrl = dirEnumerator.nextObject() as? URL {
                                if imageUrl.pathExtension.lowercased() == "png" || imageUrl.pathExtension.lowercased() == "jpg" {
                                    images.append(imageUrl)
                                }
                            }
                        }
                        
                        let adobeHtmlFile = AdobeHtmlFile(url: url, fileName: fileName, width: width, height: height, compositionId: compositionId, images: images)
                        htmlFiles.append(adobeHtmlFile)
                    } else {
                        print("Found Generic HTML file: \(url.path)")
                    }
                }
            }
        }
        
        print("Total files scanned: \(fileCount)")
        print("HTML files found: \(htmlFiles.count)")
        
        if htmlFiles.isEmpty {
            errorMessage = "No Adobe HTML files found in the selected folder"
            step1Complete = false
        } else {
            // Only set step1Complete to true if we have a folder selected AND found HTML files
            step1Complete = selectedFolderURL != nil && !htmlFiles.isEmpty
        }
        
        isSearching = false
    }

    func overwriteFile(file: AdobeHtmlFile) throws {

        statusMessage = "updating: \(file.fileName)"
               
        let newHtml = """
            <!DOCTYPE html>
            <html>
            <head>
            <meta charset="UTF-8">
            <meta name="authoring-tool" content="Adobe_Animate_CC">
            <title>\(file.fileName)</title>

            <!-- HTML Template by Donut Shop -->
            
            <script src="https://code.createjs.com/1.0.0/createjs.min.js"></script>
            <script src="\(file.fileName).js?1744093465885"></script>

            <script>var clickTag = "\(clickTagUrl)";</script>

            <script>
            var canvas, stage, exportRoot, anim_container, dom_overlay_container, fnStartAnimation;
            function init() {
                canvas = document.getElementById("canvas");
                anim_container = document.getElementById("animation_container");
                dom_overlay_container = document.getElementById("dom_overlay_container");
            \(file.compositionId)
                var lib=comp.getLibrary();
                var loader = new createjs.LoadQueue(false);
                loader.addEventListener("fileload", function(evt){handleFileLoad(evt,comp)});
                loader.addEventListener("complete", function(evt){handleComplete(evt,comp)});
                var lib=comp.getLibrary();
                loader.loadManifest(lib.properties.manifest);

                canvas.addEventListener("click", clickThrough);
            }

            function clickThrough() {
                window.open(clickTag);
            }

            function handleFileLoad(evt, comp) {
                var images=comp.getImages();    
                if (evt && (evt.item.type == "image")) { images[evt.item.id] = evt.result; }    
            }
            function handleComplete(evt,comp) {
                //This function is always called, irrespective of the content. You can use the variable "stage" after it is created in token create_stage.
                var lib=comp.getLibrary();
                var ss=comp.getSpriteSheet();
                var queue = evt.target;
                var ssMetadata = lib.ssMetadata;
                for(i=0; i<ssMetadata.length; i++) {
                    ss[ssMetadata[i].name] = new createjs.SpriteSheet( {"images": [queue.getResult(ssMetadata[i].name)], "frames": ssMetadata[i].frames} )
                }
                exportRoot = new lib._\(file.fileName)();
                stage = new lib.Stage(canvas);    
                //Registers the "tick" event listener.
                fnStartAnimation = function() {
                    stage.addChild(exportRoot);
                    createjs.Ticker.framerate = lib.properties.fps;
                    createjs.Ticker.addEventListener("tick", stage);
                }        
                //Code to support hidpi screens and responsive scaling.
                AdobeAn.makeResponsive(false,'both',false,1,[canvas,anim_container,dom_overlay_container]);    
                AdobeAn.compositionLoaded(lib.properties.id);
                fnStartAnimation();
            }
            </script>
            <!-- write your code here -->
            </head>
            <body onload="init();" style="margin:0px;">
                <div id="animation_container" style="background-color:rgba(255, 255, 255, 1.00); width:\(file.width)px; height:\(file.height)px; cursor:pointer">
                    <canvas id="canvas" width="\(file.width)" height="\(file.height)" style="position: absolute; display: block; background-color:rgba(255, 255, 255, 1.00);"></canvas>
                    <div id="dom_overlay_container" style="pointer-events:none; overflow:hidden; width:\(file.width)px; height:\(file.height)px; position: absolute; left: 0px; top: 0px; display: block;">
                    </div>
                </div>
            </body>
            </html>
            """
        
        try newHtml.write(to: file.url, atomically: true, encoding: String.Encoding.utf8)

        // Compress images using TinyPNG API
        if !file.images.isEmpty {
            compressImagesWithTinyPNG(images: file.images)
        }
        
        // Update the isConverted state in the htmlFiles array
        if let index = htmlFiles.firstIndex(where: { $0.url == file.url }) {
            htmlFiles[index].isConverted = true
        }
    }
    
    private func compressImagesWithTinyPNG(images: [URL]) {
        // Skip if no API key is provided
        guard !tinyPngApiKey.isEmpty else {
            errorMessage = "TinyPNG API key not configured"
            return
        }
        
        // Use a dispatch group to track completion of all compression tasks
        let compressionGroup = DispatchGroup()
        
        for imageURL in images {
            compressionGroup.enter() // Enter the group for each image
            
            do {
                // Read the image data
                let imageData = try Data(contentsOf: imageURL)
                
                // Create a URL request for TinyPNG API
                var request = URLRequest(url: URL(string: "https://api.tinify.com/shrink")!)
                request.httpMethod = "POST"
                request.httpBody = imageData
                
                // Add authorization header with API key
                let authString = "api:\(tinyPngApiKey)"
                if let authData = authString.data(using: .utf8) {
                    let base64Auth = authData.base64EncodedString()
                    request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
                }
                
                // Create a task to upload the image
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self.errorMessage = "Error compressing image: \(error.localizedDescription)"
                        }
                        compressionGroup.leave() // Leave the group even if there's an error
                        return
                    }
                    
                    guard let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                          let output = json["output"] as? [String: Any],
                          let url = output["url"] as? String else {
                        DispatchQueue.main.async {
                            self.errorMessage = "Invalid response from TinyPNG"
                        }
                        compressionGroup.leave() // Leave the group even if there's an error
                        return
                    }
                    
                    // Download the compressed image
                    let downloadTask = URLSession.shared.dataTask(with: URL(string: url)!) { compressedData, _, _ in
                        if let compressedData = compressedData {
                            do {
                                // Write the compressed data back to the original file
                                try compressedData.write(to: imageURL)
                                print("Compressed image saved to: \(imageURL.path)")
                                DispatchQueue.main.async {
                                    self.statusMessage = "Compressed: \(imageURL.lastPathComponent)"
                                }
                            } catch {
                                DispatchQueue.main.async {
                                    self.errorMessage = "Error saving compressed image: \(error.localizedDescription)"
                                }
                            }
                        }
                        compressionGroup.leave() // Leave the group after download task completes
                    }
                    downloadTask.resume()
                }
                task.resume()
                
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error reading image data: \(error.localizedDescription)"
                }
                compressionGroup.leave() // Leave the group if there's an error reading the image
            }
        }
        
        // When all compression tasks are done, update the status message
        compressionGroup.notify(queue: .main) {
            self.statusMessage = "ClickTag added, images compressed, you're done!"
        }
    }
    
    // URL handling is now done directly in ClickTagCell
}

//#Preview {
//    ContentView()
//}




