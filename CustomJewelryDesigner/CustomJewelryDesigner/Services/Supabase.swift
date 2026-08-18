//
//  Supabase.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//
//
//import Foundation
//import Supabase
//
//let supabase = SupabaseClient(
//  supabaseURL: URL(string: SupabaseConfig.url)!,
//  supabaseKey: SupabaseConfig.anonKey,
//  options: SupabaseClientOptions(
//	auth:  SupabaseClientOptions.AuthOptions(
//		  emitLocalSessionAsInitialSession: true // 👈 Fixes the delay,
//	  )
//  )
//)

import Foundation
import Supabase

private let supabaseURL = SupabaseConfig.url
private let supabaseKey = SupabaseConfig.anonKey

let supabase: SupabaseClient = {
    print("URL string: '\(supabaseURL)'")
    print("Key string: '\(supabaseKey)'")
    
    return SupabaseClient(
        supabaseURL: URL(string: supabaseURL)!,
        supabaseKey: SupabaseConfig.anonKey,
        options: SupabaseClientOptions(
            auth: SupabaseClientOptions.AuthOptions(
                emitLocalSessionAsInitialSession: true
            )
        )
    )
}()

