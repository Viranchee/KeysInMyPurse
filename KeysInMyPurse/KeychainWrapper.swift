//
//  KeychainWrapper.swift
//  KeysInMyPurse
//
//  Created by Viranchee L on 03/08/19.
//  Copyright © 2019 Viranchee L. All rights reserved.
//

import Foundation


/// Tie down the keychain to a Service and an Account
protocol KeychainAccessGroup {
  
  var account: String { get }
  
  init(account: String)
  
  func readToken() throws -> String
  func saveToken(_ password: String) throws
  
  func getAllTokens() throws -> [String : AnyObject]
  
//  static func readModel<Model: Decodable>() throws -> Model
//  static func saveModel<Model: Encodable>(_ model: Model) throws
  
}

struct KeychainWrapper: KeychainAccessGroup {
  
  enum KeychainError: Error {
    case noPassword
    case noItem
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
  }
  
  static let defaultService = { return "Popviewers" }()
  static let googleAccessToken = { return "googleAccessToken"}()
  
  private(set) let account: String
  
  init(account: String) {
    self.account = account
  }
  
  func readToken() throws -> String {
    var query = defaultQuery
    /// MARK:- Build on the search query
    query[kSecMatchLimit as String]       = kSecMatchLimitOne
    query[kSecReturnAttributes as String] = kCFBooleanTrue
    query[kSecReturnData as String]       = kCFBooleanTrue
    
    ///  MARK:- Initiate Search
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    
    guard status != errSecItemNotFound  else { throw KeychainError.noPassword }
    guard status == noErr               else { throw KeychainError.unhandledError(status: status) }
    /// No error, found successfully, proceed
    
    /// MARK:- Extract Result
    guard let existingItem = item as? [String : Any ],
      let tokenData = existingItem[kSecValueData as String] as? Data,
      let token = String(data: tokenData, encoding: .utf8)
      //    let account = existingItem[kSecAttrAccount as String] as? String
      else { throw KeychainError.unexpectedPasswordData }
    
    return token
    
  }
  
  func saveToken(_ token: String) throws {
    let encodedToken = token.data(using: .utf8)
    do {
      /// Check if password exists for that account
      try _ = readToken()
      
      /// Now since the password exists, update it
      var attributesToUpdate = [String : AnyObject]()
      attributesToUpdate[kSecValueData as String] = encodedToken as AnyObject?
      
      let query = defaultQuery
      let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
      
      // Throw an error if an unexpected status was returned.
      guard status == noErr else { throw KeychainError.unhandledError(status: status)
      }
      
    }
    catch KeychainError.noPassword {
      var newItem = defaultQuery
      newItem[kSecValueData as String] = encodedToken as AnyObject?
      let status = SecItemAdd(newItem as CFDictionary, nil)
      
      guard status == noErr else { throw KeychainError.unhandledError(status: status)}
      
    }
  }
  
  ///Generates query based on Account name
  private var defaultQuery: [String : AnyObject] {
    let query: [String: AnyObject] =
      [
        /// Generic Password class because no need to handle Server Attribute
        kSecClass as String       : kSecClassGenericPassword,
        kSecAttrAccount as String : account as AnyObject,
        /// TODO:- Might be need to remove KeychainService for password sharing, ask team
        kSecAttrService as String : KeychainWrapper.defaultService as AnyObject
    ]
    
    return query
  }
  
  func getAllTokens() throws -> [String : AnyObject] {
    var query = defaultQuery
    return [:]
  }
  
  static func queryFor(service: String, account: String? = nil, accessGroup: String? = nil) -> [String : AnyObject] {
    
    var query: [String : AnyObject] = [
      kSecClass as String           : kSecClassGenericPassword,
      kSecAttrService as String     : service as AnyObject,
    ]
    /// Dictionary properties accessed via Brackets are optional, so set with optional
    query[kSecAttrAccount as String] = account as AnyObject
    query[kSecAttrAccessGroup as String] = accessGroup as AnyObject
    
    return query
  }

  static func passwordItems(forService service: String, accessGroup: String? = nil) -> [KeychainWrapper] {
    
    let query = KeychainWrapper.queryFor(service: service, accessGroup: accessGroup)
    
  }
}

/// Helpful extensions
extension KeychainWrapper {
  func saveGoogleAccess(token: String) {
    let account = KeychainWrapper(account: KeychainWrapper.googleAccessToken)
    try? account.saveToken(token)
  }
  
  /// This method retrives GoogleAccess key
  ///
  /// - Returns: Either the AccessToken or Empty String. Check for if empty before using
  func retriveGoogleAccess() -> String {
    let account = KeychainWrapper(account: KeychainWrapper.googleAccessToken)
    let password = try? account.readToken()
    return password ?? ""
  }
}
