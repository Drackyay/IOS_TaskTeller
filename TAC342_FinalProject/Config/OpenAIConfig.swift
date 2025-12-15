//
//  OpenAIConfig.swift
//  TAC342_FinalProject
//
//  Configuration helper to load OpenAI API key from Secrets.plist
//

import Foundation

/// Configuration helper for loading secrets from plist files
/// This keeps API keys out of source code and version control
struct OpenAIConfig {
    
    /// The OpenAI API key loaded from Secrets.plist
    /// Returns nil if the plist or key is not found
    static var apiKey: String? {
        // Locate Secrets.plist in the main bundle
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist") else {
            print("⚠️ Secrets.plist not found in bundle")
            return nil
        }
        
        // Load the plist data
        guard let data = try? Data(contentsOf: url) else {
            print("⚠️ Could not read Secrets.plist")
            return nil
        }
        
        // Parse as dictionary
        guard let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            print("⚠️ Could not parse Secrets.plist")
            return nil
        }
        
        // Extract the API key
        guard let key = plist["OPENAI_API_KEY"] as? String, key != "YOUR_OPENAI_API_KEY_HERE" else {
            print("⚠️ OPENAI_API_KEY not set in Secrets.plist")
            return nil
        }
        
        return key
    }
}

