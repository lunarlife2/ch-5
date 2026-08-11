//
//  RingSize.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 11/08/26.
//

struct RingSize: Identifiable {
	let id: Int
	let size: String
	let diameterMM: Double
	let circumferenceMM: Double
}

let ringSizes: [RingSize] = [
	RingSize(id: 1, size: "3",   diameterMM: 14.1, circumferenceMM: 44.2),
	RingSize(id: 2, size: "3.5", diameterMM: 14.5, circumferenceMM: 45.5),
	RingSize(id: 3, size: "4",   diameterMM: 14.9, circumferenceMM: 46.8),
	RingSize(id: 4, size: "4.5", diameterMM: 15.3, circumferenceMM: 48.0),
	RingSize(id: 5, size: "5",   diameterMM: 15.7, circumferenceMM: 49.3),
	RingSize(id: 6, size: "5.5", diameterMM: 16.1, circumferenceMM: 50.6),
	RingSize(id: 7, size: "6",   diameterMM: 16.5, circumferenceMM: 51.9),
	RingSize(id: 8, size: "6.5", diameterMM: 16.9, circumferenceMM: 53.1),
	RingSize(id: 9, size: "7",   diameterMM: 17.3, circumferenceMM: 54.4),
	RingSize(id: 10, size: "7.5", diameterMM: 17.7, circumferenceMM: 55.7),
	RingSize(id: 11, size: "8",   diameterMM: 18.1, circumferenceMM: 57.0),
	RingSize(id: 12, size: "8.5", diameterMM: 18.5, circumferenceMM: 58.3),
	RingSize(id: 13, size: "9",   diameterMM: 18.9, circumferenceMM: 59.5),
	RingSize(id: 14, size: "9.5", diameterMM: 19.4, circumferenceMM: 60.8),
	RingSize(id: 15, size: "10",  diameterMM: 19.8, circumferenceMM: 62.1),
	RingSize(id: 16, size: "10.5", diameterMM: 20.2, circumferenceMM: 63.4),
	RingSize(id: 17, size: "11",  diameterMM: 20.6, circumferenceMM: 64.6),
	RingSize(id: 18, size: "11.5", diameterMM: 21.0, circumferenceMM: 65.9),
	RingSize(id: 19, size: "12",  diameterMM: 21.4, circumferenceMM: 67.2),
	RingSize(id: 20, size: "12.5", diameterMM: 21.8, circumferenceMM: 68.5),
	RingSize(id: 21, size: "13",  diameterMM: 22.2, circumferenceMM: 69.7),
	RingSize(id: 22, size: "13.5", diameterMM: 22.6, circumferenceMM: 71.0),
	RingSize(id: 23, size: "14",  diameterMM: 23.0, circumferenceMM: 72.3)
]
