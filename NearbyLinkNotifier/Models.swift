// Models.swift
import Foundation

struct Link: Codable { // Use Codable to support both Decodable and Encodable
    let link: String
    let location: [String: Double]?
}
