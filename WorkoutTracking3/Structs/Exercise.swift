//
//  Exercise.swift
//  WorkoutTracking3
//
//  Created by Chris Peloso on 3/9/22.
//

import Foundation

struct Exercise: Codable, Identifiable, Hashable {
    
    var id: UUID { return UUID() }
    
    let name: String
    let description: String
    let formImage: String
    let musclesImage: String
    
    
    //  computed property
    var shortDescription: String {
        
        var shortDesc = description.trimmingCharacters(in: ["\n"])
        
        if(shortDesc.count > 40) {
            shortDesc = shortDesc.substring(with: 0..<40) + "..."
        }
        
        return shortDesc
    }
}
