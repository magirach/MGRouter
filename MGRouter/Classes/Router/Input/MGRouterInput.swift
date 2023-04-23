//
//  MGRouterInput.swift
//
//  Created by Moinuddin Girach on 17/06/20.
//

import Foundation

public enum RouterMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public protocol MGRouterInputProtocol: class {
    var baseUrl: String? {get set}
    var endpoint: String {get set}
    var body: Data? {get set}
    var headers: [String: String] {get set}
    var timeout: Int {get set}
    var method: RouterMethod {get set}
    var cacheResponse: Bool {get set}
    var requestInterceptors: [InterceptorProtocol] { get }
    var responseInterceptors: [InterceptorProtocol] { get }
    
    func addIntercetpors(interceptor: InterceptorProtocol, isRequest: Bool)
}

public protocol DataConvertable {
    var data:Data? {get}
}

open class MGRouterInput: MGRouterInputProtocol {
    
    public var baseUrl: String?
    
    /// api endpoint
    public var endpoint: String
    
    /// request body
    public var body: Data?
    
    /// request headers
    public var headers: [String : String] = [:]
    
    /// timeout interval
    public var timeout: Int
    
    /// HttpMethod
    public var method: RouterMethod
    
    /// true if responce needs to be cached
    public var cacheResponse: Bool = false
        
    /// initialize router input
    /// - Parameters:
    ///   - endpoint: enpoint string
    ///   - urlParams: url query params
    ///   - body: request body data in case of post or put methods
    ///   - method: Http request method
    ///   - timeout: response time out
    ///   - arguments: url parameters
    public init(baseUrl: String? = nil,
                endpoint: String,
                urlParams: [String: Any] = [:],
                body: DataConvertable? = nil,
                method: RouterMethod = .get,
                timeout: Int = 30 ,
                arguments: [CVarArg] = []) {
        self.baseUrl = baseUrl
        self.body = body?.data
        self.timeout = timeout
        self.method = method
        
        var endpointWitArgs = endpoint
        if !arguments.isEmpty {
            endpointWitArgs = String(format: endpoint, arguments: arguments)
        }
        
        if urlParams.isEmpty {
            self.endpoint = endpointWitArgs
        } else {
            var urlc = URLComponents()
            urlc.queryItems = [URLQueryItem]()
            for (key, value) in urlParams {
                let queryItem = URLQueryItem(name: key, value: "\(value)")
                urlc.queryItems!.append(queryItem)
            }
            self.endpoint = "\(endpointWitArgs)?\(urlc.percentEncodedQuery ?? "")"
        }
    }
    
    public func addIntercetpors(interceptor: InterceptorProtocol, isRequest: Bool) {
        if isRequest {
            requestInterceptors.append(interceptor)
        } else {
            responseInterceptors.append(interceptor)
        }
    }
    
    public private(set) var requestInterceptors: [InterceptorProtocol] = []
    public private(set) var responseInterceptors: [InterceptorProtocol] = []
}
