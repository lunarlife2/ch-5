//
//  RingSizeOption.swift
//  CustomJewelryDesigner
//
//  Created by Yimei Winata on 14/08/26.
//

import Foundation
import SwiftUI

enum RingSizeSystem: String, CaseIterable, Identifiable {
    case usCanada
    case ukAustralia
    case eu
    case japan
    case hongkong
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .usCanada:
            return "US / Canada"
        case .ukAustralia:
            return "UK / Australia"
        case .hongkong:
            return "Hongkong"
        case .eu:
            return "EU"
        case .japan:
            return "Japan"
        }
    }
}

struct RingSizeOption: Identifiable {
    let id: Int
    
    let diameterMM: Double
    let circumferenceMM: Double
    
    let usCanada: String
    let hongKong: String?
    let eu: String?
    let ukAustralia: String?
    let japan: String?
}

extension RingSizeOption {
    func size(for system: RingSizeSystem) -> String? {
        switch system {
        case .usCanada:
            return usCanada

        case .ukAustralia:
            return ukAustralia

        case .eu:
            return eu

        case .japan:
            return japan

        case .hongkong:
            return hongKong
        }
    }
}

let ringSizeOptions: [RingSizeOption] = [

    RingSizeOption(
        id: 1,
        diameterMM: 13.5,
        circumferenceMM: 42.4,
        usCanada: "2.25",
        hongKong: nil,
        eu: nil,
        ukAustralia: nil,
        japan: nil
    ),

    RingSizeOption(
        id: 2,
        diameterMM: 13.7,
        circumferenceMM: 43.0,
        usCanada: "2.5",
        hongKong: nil,
        eu: nil,
        ukAustralia: nil,
        japan: nil
    ),

    RingSizeOption(
        id: 3,
        diameterMM: 13.9,
        circumferenceMM: 43.7,
        usCanada: "2.75",
        hongKong: nil,
        eu: "44",
        ukAustralia: "F",
        japan: nil
    ),

    RingSizeOption(
        id: 4,
        diameterMM: 14.1,
        circumferenceMM: 44.3,
        usCanada: "3",
        hongKong: "6",
        eu: "44",
        ukAustralia: "F½",
        japan: "4"
    ),

    RingSizeOption(
        id: 5,
        diameterMM: 14.3,
        circumferenceMM: 44.9,
        usCanada: "3.25",
        hongKong: nil,
        eu: "45",
        ukAustralia: "G",
        japan: "5"
    ),

    RingSizeOption(
        id: 6,
        diameterMM: 14.5,
        circumferenceMM: 45.6,
        usCanada: "3.5",
        hongKong: "7",
        eu: "46",
        ukAustralia: "G½",
        japan: nil
    ),

    RingSizeOption(
        id: 7,
        diameterMM: 14.7,
        circumferenceMM: 46.2,
        usCanada: "3.75",
        hongKong: nil,
        eu: "46",
        ukAustralia: "H",
        japan: "6"
    ),

    RingSizeOption(
        id: 8,
        diameterMM: 14.9,
        circumferenceMM: 46.8,
        usCanada: "4",
        hongKong: "8",
        eu: "47",
        ukAustralia: "H½",
        japan: "7"
    ),

    RingSizeOption(
        id: 9,
        diameterMM: 15.1,
        circumferenceMM: 47.4,
        usCanada: "4.25",
        hongKong: nil,
        eu: "47",
        ukAustralia: "I",
        japan: nil
    ),

    RingSizeOption(
        id: 10,
        diameterMM: 15.3,
        circumferenceMM: 48.1,
        usCanada: "4.5",
        hongKong: "9",
        eu: "48",
        ukAustralia: "I½",
        japan: "8"
    ),

    RingSizeOption(
        id: 11,
        diameterMM: 15.5,
        circumferenceMM: 48.7,
        usCanada: "4.75",
        hongKong: "10",
        eu: "49",
        ukAustralia: "J",
        japan: nil
    ),

    RingSizeOption(
        id: 12,
        diameterMM: 15.7,
        circumferenceMM: 49.3,
        usCanada: "5",
        hongKong: nil,
        eu: "49",
        ukAustralia: "J½",
        japan: "9"
    ),

    RingSizeOption(
        id: 13,
        diameterMM: 15.9,
        circumferenceMM: 50.0,
        usCanada: "5.25",
        hongKong: "11",
        eu: "50",
        ukAustralia: "K",
        japan: nil
    ),

    RingSizeOption(
        id: 14,
        diameterMM: 16.1,
        circumferenceMM: 50.6,
        usCanada: "5.5",
        hongKong: nil,
        eu: "51",
        ukAustralia: "K½",
        japan: "10"
    ),

    RingSizeOption(
        id: 15,
        diameterMM: 16.3,
        circumferenceMM: 51.2,
        usCanada: "5.75",
        hongKong: "12",
        eu: "51",
        ukAustralia: "L",
        japan: nil
    ),

    RingSizeOption(
        id: 16,
        diameterMM: 16.5,
        circumferenceMM: 51.8,
        usCanada: "6",
        hongKong: "13",
        eu: "52",
        ukAustralia: "L½",
        japan: "11"
    ),

    RingSizeOption(
        id: 17,
        diameterMM: 16.7,
        circumferenceMM: 52.5,
        usCanada: "6.25",
        hongKong: nil,
        eu: "52",
        ukAustralia: "M",
        japan: "12"
    ),

    RingSizeOption(
        id: 18,
        diameterMM: 16.9,
        circumferenceMM: 53.1,
        usCanada: "6.5",
        hongKong: "14",
        eu: "53",
        ukAustralia: "M½",
        japan: "13"
    ),

    RingSizeOption(
        id: 19,
        diameterMM: 17.1,
        circumferenceMM: 53.7,
        usCanada: "6.75",
        hongKong: nil,
        eu: "54",
        ukAustralia: "N",
        japan: nil
    ),

    RingSizeOption(
        id: 20,
        diameterMM: 17.3,
        circumferenceMM: 54.4,
        usCanada: "7",
        hongKong: "15",
        eu: "54",
        ukAustralia: "N½",
        japan: "14"
    ),

    RingSizeOption(
        id: 21,
        diameterMM: 17.5,
        circumferenceMM: 55.0,
        usCanada: "7.25",
        hongKong: "16",
        eu: "55",
        ukAustralia: "O",
        japan: nil
    ),

    RingSizeOption(
        id: 22,
        diameterMM: 17.7,
        circumferenceMM: 55.6,
        usCanada: "7.5",
        hongKong: nil,
        eu: "56",
        ukAustralia: "O½",
        japan: "15"
    ),

    RingSizeOption(
        id: 23,
        diameterMM: 17.9,
        circumferenceMM: 56.2,
        usCanada: "7.75",
        hongKong: "17",
        eu: "56",
        ukAustralia: "P",
        japan: nil
    ),

    RingSizeOption(
        id: 24,
        diameterMM: 18.1,
        circumferenceMM: 56.9,
        usCanada: "8",
        hongKong: nil,
        eu: "57",
        ukAustralia: "P½",
        japan: "16"
    ),

    RingSizeOption(
        id: 25,
        diameterMM: 18.3,
        circumferenceMM: 57.5,
        usCanada: "8.25",
        hongKong: "18",
        eu: "58",
        ukAustralia: "Q",
        japan: nil
    ),

    RingSizeOption(
        id: 26,
        diameterMM: 18.5,
        circumferenceMM: 58.12,
        usCanada: "8.5",
        hongKong: nil,
        eu: "58",
        ukAustralia: "Q½",
        japan: "17"
    ),

    RingSizeOption(
        id: 27,
        diameterMM: 18.8,
        circumferenceMM: 59.0,
        usCanada: "8.75",
        hongKong: "19",
        eu: "59",
        ukAustralia: "R",
        japan: nil
    ),

    RingSizeOption(
        id: 28,
        diameterMM: 19.0,
        circumferenceMM: 59.7,
        usCanada: "9",
        hongKong: "20",
        eu: "60",
        ukAustralia: "R½",
        japan: "18"
    ),

    RingSizeOption(
        id: 29,
        diameterMM: 19.2,
        circumferenceMM: 60.3,
        usCanada: "9.25",
        hongKong: nil,
        eu: "60",
        ukAustralia: "S",
        japan: nil
    ),

    RingSizeOption(
        id: 30,
        diameterMM: 19.4,
        circumferenceMM: 60.9,
        usCanada: "9.5",
        hongKong: "21",
        eu: "61",
        ukAustralia: "S½",
        japan: "19"
    ),

    RingSizeOption(
        id: 31,
        diameterMM: 19.6,
        circumferenceMM: 61.6,
        usCanada: "9.75",
        hongKong: nil,
        eu: "62",
        ukAustralia: "T",
        japan: nil
    ),

    RingSizeOption(
        id: 32,
        diameterMM: 19.8,
        circumferenceMM: 62.2,
        usCanada: "10",
        hongKong: "22",
        eu: "62",
        ukAustralia: "T½",
        japan: "20"
    ),

    RingSizeOption(
        id: 33,
        diameterMM: 20.0,
        circumferenceMM: 62.8,
        usCanada: "10.25",
        hongKong: nil,
        eu: "63",
        ukAustralia: "U",
        japan: "21"
    ),

    RingSizeOption(
        id: 34,
        diameterMM: 20.2,
        circumferenceMM: 63.5,
        usCanada: "10.5",
        hongKong: "23",
        eu: "64",
        ukAustralia: "U½",
        japan: "22"
    ),

    RingSizeOption(
        id: 35,
        diameterMM: 20.4,
        circumferenceMM: 64.1,
        usCanada: "10.75",
        hongKong: "24",
        eu: "64",
        ukAustralia: "V",
        japan: nil
    ),

    RingSizeOption(
        id: 36,
        diameterMM: 20.6,
        circumferenceMM: 64.7,
        usCanada: "11",
        hongKong: nil,
        eu: "65",
        ukAustralia: "V½",
        japan: "23"
    ),

    RingSizeOption(
        id: 37,
        diameterMM: 20.8,
        circumferenceMM: 65.3,
        usCanada: "11.25",
        hongKong: "25",
        eu: "65",
        ukAustralia: "W",
        japan: nil
    ),

    RingSizeOption(
        id: 38,
        diameterMM: 21.0,
        circumferenceMM: 66.0,
        usCanada: "11.5",
        hongKong: nil,
        eu: "66",
        ukAustralia: "W½",
        japan: "24"
    ),

    RingSizeOption(
        id: 39,
        diameterMM: 21.2,
        circumferenceMM: 66.6,
        usCanada: "11.75",
        hongKong: "26",
        eu: "67",
        ukAustralia: "X",
        japan: nil
    ),

    RingSizeOption(
        id: 40,
        diameterMM: 21.4,
        circumferenceMM: 67.2,
        usCanada: "12",
        hongKong: "27",
        eu: "67",
        ukAustralia: "X½",
        japan: "25"
    ),

    RingSizeOption(
        id: 41,
        diameterMM: 21.6,
        circumferenceMM: 67.9,
        usCanada: "12.25",
        hongKong: nil,
        eu: "68",
        ukAustralia: "Y",
        japan: nil
    ),

    RingSizeOption(
        id: 42,
        diameterMM: 21.8,
        circumferenceMM: 68.5,
        usCanada: "12.5",
        hongKong: nil,
        eu: "68",
        ukAustralia: "Z",
        japan: "26"
    ),

    RingSizeOption(
        id: 43,
        diameterMM: 22.0,
        circumferenceMM: 69.1,
        usCanada: "12.75",
        hongKong: nil,
        eu: "69",
        ukAustralia: "Z½",
        japan: nil
    ),

    RingSizeOption(
        id: 44,
        diameterMM: 22.2,
        circumferenceMM: 69.7,
        usCanada: "13",
        hongKong: nil,
        eu: "70",
        ukAustralia: nil,
        japan: "27"
    ),

    RingSizeOption(
        id: 45,
        diameterMM: 22.4,
        circumferenceMM: 70.4,
        usCanada: "13.25",
        hongKong: nil,
        eu: nil,
        ukAustralia: "Z+1",
        japan: nil
    ),

    RingSizeOption(
        id: 46,
        diameterMM: 22.6,
        circumferenceMM: 71.0,
        usCanada: "13.5",
        hongKong: nil,
        eu: nil,
        ukAustralia: "Z+2",
        japan: nil
    )
]
