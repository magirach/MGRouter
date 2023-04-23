//
//  MGSession.swift
//
//  Created by Moinuddin Girach on 17/06/20.
//

import Foundation

/// Session class. main purpose to create class is to make singalton object of URLSession. shaed object of URLSesion does not allow to cusomize configuration so neds to create custom URLSession oject and set configuration.
public class MGSession: NSObject, URLSessionDataDelegate, MGSessionProtocol  {
    public var bundle: Bundle = Bundle.main
        
    public static let `default`: MGSessionProtocol = {
            return MGSession()
    }()
    
    public static var defaultSession: URLSession? {
        return `default`.session
    }
    
    public var session: URLSession?
    
    public init(configuration: URLSessionConfiguration = URLSessionConfiguration.default) {
        session = URLSession(configuration: configuration)
    }
}
