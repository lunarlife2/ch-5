//
//  Supabase.swift
//  CustomJewelryDesigner
//
//  Created by Averina on 10/08/26.
//

import Foundation
import Supabase

let supabase = SupabaseClient(
  supabaseURL: URL(string: SupabaseConfig.url)!,
  supabaseKey: SupabaseConfig.anonKey,
  options: SupabaseClientOptions(
	auth:  SupabaseClientOptions.AuthOptions(
		  emitLocalSessionAsInitialSession: true // 👈 Fixes the delay,
	  )
  )
)



