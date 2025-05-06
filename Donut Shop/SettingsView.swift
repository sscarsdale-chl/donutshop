//
//  SettingsView.swift
//  Donut Shop
//
//  Created by Shawn Scarsdale on 5/6/25.
//

import SwiftUI
import Foundation

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var tinyPngApiKey: String
    @State private var temporaryApiKey: String = ""
    
    var body: some View {
        VStack {
            
            HStack {
                Text("TinyPNG API Key")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                
                Spacer()
            }
            
            Form {
                Section {
                    
                    HStack{
                        
                        VStack{
                            TextField("", text: $temporaryApiKey)
                                .autocorrectionDisabled()
                            
                            if !temporaryApiKey.isEmpty {
                                Text("API keys are saved securely in your user preferences")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        VStack{
                            Button("Save") {
                                tinyPngApiKey = temporaryApiKey
                                UserDefaults.standard.set(temporaryApiKey, forKey: "tinyPngApiKey")
                                dismiss()
                            }
                            .padding(.horizontal)
                            
                            Spacer()
                        }

                        
                    }


                }
                
            }
            .padding()
            .navigationTitle("Settings")
            .onAppear {
                temporaryApiKey = tinyPngApiKey
            }
            
            HStack {
                Link("Get a TinyPNG API key", destination: URL(string: "https://tinypng.com/developers")!)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
            }
            .padding()
        }
    }
}


