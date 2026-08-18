//
//  JewelryDropPayload.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 17/08/26.
//
import Supabase
import Foundation
import SwiftUI
internal import UniformTypeIdentifiers

struct JewelryDropPayload: Codable, Transferable {
    let type: String
    let id: UUID

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}
