// Models.swift
import Foundation

struct SpotterLink: Codable {
    let link: String
    let location: [String: Double]?
    let description: String? // Optional field for description
    let imageURL: String? 
}
