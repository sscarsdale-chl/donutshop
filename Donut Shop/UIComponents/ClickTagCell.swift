//
//  ClickTagCell.swift
//  Donut Shop
//
//  Created by Shawn Scarsdale on 5/5/25.
//

import SwiftUI

struct ClickTagCell: View {
    @Binding var clickTagUrl: String
    @Binding var step2Complete: Bool
    @State private var isValidUrl: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    private func validateURL() -> Bool {
        guard !clickTagUrl.isEmpty else { return false }
        
        // Add "https://" if no scheme is provided
        var urlToCheck = clickTagUrl
        if !urlToCheck.contains("://") {
            urlToCheck = "https://" + urlToCheck
        }
        
        // Check if the URL has a valid format with a domain
        if let url = URL(string: urlToCheck) {
            // Check for a valid domain with at least one dot
            let host = url.host ?? ""
            return (url.scheme == "http" || url.scheme == "https") && host.contains(".")
        }
        
        return false
    }
    
    // Format the URL properly with a scheme
    private func formatURL() {
        guard !clickTagUrl.isEmpty else { return }
        
        // Remove any leading/trailing whitespace
        var formattedUrl = clickTagUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add https:// if no scheme is provided
        if !formattedUrl.contains("://") {
            formattedUrl = "https://" + formattedUrl
        } else if !formattedUrl.hasPrefix("https://") && formattedUrl.hasPrefix("http://") {
            // Replace http:// with https://
            formattedUrl = "https://" + formattedUrl.dropFirst("http://".count)
        }
        
        // Ensure the URL has a valid format
        if let url = URL(string: formattedUrl) {
            clickTagUrl = url.absoluteString
        } else {
            // If URL creation fails, keep the current format but ensure it starts with https://
            clickTagUrl = formattedUrl
        }
        
        // Update validity and step2Complete
        isValidUrl = validateURL()
        step2Complete = isValidUrl
    }
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 20) {
            
            ZStack {
                Circle()
                    .fill(step2Complete ? Color.green : Color.black)
                    .frame(width: 32, height: 32)
                Text("2")
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .padding()
            
            Text("ClickTag:")
                .foregroundColor(.dsPrimaryText)
                .fontWeight(.bold)
                .font(.headline)
                
            TextField("ClickTag URL", text: $clickTagUrl)
                .foregroundColor(.dsPrimaryText)
                .fontWeight(.bold)
                .font(.headline)
                .cornerRadius(5)
                .textFieldStyle(PlainTextFieldStyle())
                .onChange(of: clickTagUrl) { oldValue, newValue in
                    isValidUrl = validateURL()
                    step2Complete = isValidUrl
                    print("URL changed to: \(newValue), valid: \(isValidUrl)")
                }
                .onSubmit {
                    formatURL()
                }
                .focused($isTextFieldFocused)
                .onChange(of: isTextFieldFocused) { oldValue, newValue in
                    if oldValue && !newValue {  // Lost focus
                        formatURL()
                    }
                }
            
            Spacer()
                        
        }
        .background(.dsLightGray)
        .cornerRadius(10)
        .onAppear {
            isValidUrl = validateURL()
            step2Complete = isValidUrl
            print("ClickTagCell appeared, URL: \(clickTagUrl), valid: \(isValidUrl)")
        }
    }
}

//// Preview provider for SwiftUI Canvas
//struct ClickTagCell_Previews: PreviewProvider {
//    static var previews: some View {
//        ClickTagCell(clickTagUrl: .constant("https://www.example.com"), step2Complete: false)
//    }
//}
