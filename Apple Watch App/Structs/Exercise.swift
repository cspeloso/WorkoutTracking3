//
//  Exercise.swift
//  Work It Out Apple Watch Watch App
//
//  Created by Chris Peloso on 1/12/24.
//

import Foundation

struct Exercise: Codable, Identifiable, Hashable {
    
    var id: UUID { return UUID() }
    
    let name: String
    let description: String
    let formImage: String
    let musclesImage: String
    let muscleGroups: [String]
    
    
    //  computed property
//    var shortDescription: String {
//        
//        var shortDesc = description.trimmingCharacters(in: ["\n"])
//        
//        if(shortDesc.count > 40) {
//            shortDesc = shortDesc.substring(with: 0..<40) + "..."
//        }
//        
//        return shortDesc
//    }
    var shortDescription: String {
        var shortDesc = description.trimmingCharacters(in: ["\n"])
        
        if shortDesc.count > 40 {
            let endIndex = shortDesc.index(shortDesc.startIndex, offsetBy: 40, limitedBy: shortDesc.endIndex) ?? shortDesc.endIndex
            shortDesc = String(shortDesc[..<endIndex]) + "..."
        }
        
        return shortDesc
    }

}
