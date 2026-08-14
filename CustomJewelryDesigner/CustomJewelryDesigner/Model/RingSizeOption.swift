//
//  RingSizeOption.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//

import Foundation
import SwiftUI

struct RingSizeOption: Identifiable {
    let id: Int
    let size: String
    let diameterMM: Double
    let circumferenceMM: Double
}

let usCanadaRingSizes: [RingSizeOption] = [
    RingSizeOption(id: 1, size: "3",   diameterMM: 14.1, circumferenceMM: 44.2),
    RingSizeOption(id: 2, size: "3.5", diameterMM: 14.5, circumferenceMM: 45.5),
    RingSizeOption(id: 3, size: "4",   diameterMM: 14.9, circumferenceMM: 46.8),
    RingSizeOption(id: 4, size: "4.5", diameterMM: 15.3, circumferenceMM: 48.0),
    RingSizeOption(id: 5, size: "5",   diameterMM: 15.7, circumferenceMM: 49.3),
    RingSizeOption(id: 6, size: "5.5", diameterMM: 16.1, circumferenceMM: 50.6),
    RingSizeOption(id: 7, size: "6",   diameterMM: 16.5, circumferenceMM: 51.9),
    RingSizeOption(id: 8, size: "6.5", diameterMM: 16.9, circumferenceMM: 53.1),
    RingSizeOption(id: 9, size: "7",   diameterMM: 17.3, circumferenceMM: 54.4),
    RingSizeOption(id: 10, size: "7.5", diameterMM: 17.7, circumferenceMM: 55.7),
    RingSizeOption(id: 11, size: "8",   diameterMM: 18.1, circumferenceMM: 57.0),
    RingSizeOption(id: 12, size: "8.5", diameterMM: 18.5, circumferenceMM: 58.3),
    RingSizeOption(id: 13, size: "9",   diameterMM: 18.9, circumferenceMM: 59.5),
    RingSizeOption(id: 14, size: "9.5", diameterMM: 19.4, circumferenceMM: 60.8),
    RingSizeOption(id: 15, size: "10",  diameterMM: 19.8, circumferenceMM: 62.1),
    RingSizeOption(id: 16, size: "10.5", diameterMM: 20.2, circumferenceMM: 63.4),
    RingSizeOption(id: 17, size: "11",  diameterMM: 20.6, circumferenceMM: 64.6),
    RingSizeOption(id: 18, size: "11.5", diameterMM: 21.0, circumferenceMM: 65.9),
    RingSizeOption(id: 19, size: "12",  diameterMM: 21.4, circumferenceMM: 67.2),
    RingSizeOption(id: 20, size: "12.5", diameterMM: 21.8, circumferenceMM: 68.5),
    RingSizeOption(id: 21, size: "13",  diameterMM: 22.2, circumferenceMM: 69.7),
    RingSizeOption(id: 22, size: "13.5", diameterMM: 22.6, circumferenceMM: 71.0),
    RingSizeOption(id: 23, size: "14",  diameterMM: 23.0, circumferenceMM: 72.3)
]
