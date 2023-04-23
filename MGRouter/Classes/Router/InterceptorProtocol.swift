//
//  InterceptorProtocol.swift
//  MGRouter
//
//  Created by Moinuddin Girach on 23/04/23.
//

import Foundation

public protocol InterceptorProtocol: AnyObject {
    func interCeptRequest(request: URLRequest) -> URLRequest
    func interCeptResponse(data: Data?,
                           response: URLResponse?,
                           error: Error?) -> (data: Data?,
                                              response: URLResponse?,
                                              error: Error?)
}
