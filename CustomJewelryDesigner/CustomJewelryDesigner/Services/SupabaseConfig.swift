//
//  SupabaseConfig.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 11/08/26.
//
import Foundation

enum SupabaseConfig {
	static var url: String {
		Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as! String
	}
	static var anonKey: String {
		Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as! String
	}
}
