// Models.swift
import Foundation

struct Link: Codable {
    let link: String
    let location: [String: Double]?
    let description: String? // Optional field for description
}
