//
//  MGSessionProtocol.swift
//
//  Created by Moinuddin Girach on 17/06/20.
//

import Foundation

public protocol MGSessionProtocol: class {
    static var `default`: MGSessionProtocol { get }
    static var defaultSession: URLSession? { get }
    var session: URLSession? {get set}
    var bundle: Bundle {get set}
}
