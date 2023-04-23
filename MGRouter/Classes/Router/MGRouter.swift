//
//  MGRouter.swift
//
//  Created by Moinuddin Girach on 17/06/20.
//

import Foundation

public struct MGRouter {
    
    static let `default` = MGRouter()
    
    public var debug = false
    public var encodingStratagy = JSONEncoder.KeyEncodingStrategy.convertToSnakeCase
    public var decodingStratagy = JSONDecoder.KeyDecodingStrategy.convertFromSnakeCase

    public var baseUrl: String = ""
    
    public private(set) var session: MGSessionProtocol
      
    public init(session: MGSessionProtocol = MGSession.default) {
        self.session = session
    }
    
    func baseUrl(input: MGRouterInputProtocol) -> String {
        return input.baseUrl ?? baseUrl
    }
    
    /// custom headers
    func headers(input: MGRouterInputProtocol) -> [String: String] {
        return input.headers
    }
    
    func method(input: MGRouterInputProtocol) ->  String {
        return input.method.rawValue
    }
    
    func timeout(input: MGRouterInputProtocol) ->  TimeInterval {
        return TimeInterval(input.timeout)
    }
    
    func body(input: MGRouterInputProtocol) ->  Data? {
        return input.body
    }
    
    /// final url
    func url(input: MGRouterInputProtocol) ->  URL {
        let strUrl = String(format: "%@%@", baseUrl(input: input), input.endpoint)
        return URL(string: strUrl)!
    }
    
    func request(input: MGRouterInputProtocol) ->  URLRequest {
        var request: URLRequest = URLRequest(url: url(input: input))
        request.httpMethod = method(input: input)
        request.timeoutInterval = timeout(input: input)
        request.httpBody = input.body
        
        for (key, value) in headers(input: input) {
            request.addValue(value, forHTTPHeaderField: key)
        }
        return request
    }
}

extension MGRouter {
    
    public func call<T: Decodable>(input: MGRouterInputProtocol,
                                   callback: @escaping (Result<T?, Error>) -> Void) {
        self.apiCall(input: input,
                     callback: callback)
    }
    
    
    /// make network api calls
    /// - Parameter callback: callback blocak
    internal func apiCall<T: Decodable>(input: MGRouterInputProtocol,
                                        callback: @escaping (Result<T?, Error>) -> Void) {
        var request = request(input: input)
        for interceptor in input.requestInterceptors {
            request = interceptor.interCeptRequest(request: request)
        }
        let task = session.session!.dataTask(with: request) { (data, response, error) in
            var data = data
            var response = response
            var error = error
            for interceptor in input.responseInterceptors {
                let res = interceptor.interCeptResponse(data: data, response: response, error: error)
                data = res.data
                response = res.response
                error = res.error
            }
            let responseStatusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            
            if let error = error {
                DispatchQueue.main.async {
                    callback(.failure(error))
                }
                return
            }
            
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    let error = NSError(domain: "com.moin.error", code: responseStatusCode, userInfo: ["description": "Invalid data"])
                    callback(.failure(error))
                }
                return
            }

            if data.isEmpty && T.self != Data.self {
                DispatchQueue.main.async {
                    let error = NSError(domain: "com.moin.error", code: responseStatusCode, userInfo: ["description": "Empty response"])
                    callback(.failure(error))
                }
                return
            }
            if debug {
                print("=================\nREQUEST\n=================")
                print("URL: \(url(input: input))")
                print("-----------------\nMETHOD:\(input.method)\n-----------------")
                if let body = input.body {
                    print("BODY: \(String(data: body, encoding: .utf8)!)\n-----------------")
                }
                print("HEADERS: \(request.allHTTPHeaderFields!)")
                print("=================\nRESPONSE\n=================")
                
            }
            
            switch responseStatusCode {
            case 200, 201:
                if T.self == Data.self {
                    DispatchQueue.main.async {
                        callback(.success(data as? T))
                    }
                } else {
                    self.decode(data: data, callback: callback)
                }
            default:
                print("RESPONSE STATUS CODE: \(responseStatusCode)")
                print("STRING FROM SERVER:\(String(data: data, encoding: .utf8) ?? "Binary data")\n-----------------")
                DispatchQueue.main.async {
                    let error = NSError(domain: "com.moin.error", code: responseStatusCode, userInfo: ["description": "Response error", "data": data])
                    callback(.failure(error))
                }
            }
        }
        task.taskDescription = NSStringFromClass(type(of: input))
        task.resume()
    }
    
    /// decode data to required output
    /// - Parameters:
    ///   - data: response data
    ///   - callback: callback block after data conversion
    internal func decode<T: Decodable>(data: Data, callback: @escaping (Result<T?, Error>) -> Void) {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = decodingStratagy
        do {
            let responseData = try decoder.decode(T.self, from: data)
            if debug {
                print("\(responseData)\n=================")
            }
            DispatchQueue.main.async {
                callback(.success(responseData))
            }
        } catch {
            if debug {
                print("\(error)\n=================")
            }
            DispatchQueue.main.async {
                callback(.failure(error))
            }
        }
    }
}
