//
//  WebSocketTask.swift
//  
//
//  Created by Adam Share on 8/13/20.
//

import Foundation

@available(iOS 13.0, *)
protocol WebSocketTask: AnyObject {
    var listener: WebSocketURLSessionListener? { get set }
    var receiver: ((Result<URLSessionWebSocketTask.Message, Error>) -> Void)? { get set }
    func connect()
    func disconnect()
    func send(_ message: URLSessionWebSocketTask.Message, completionHandler: @escaping (Error?) -> Void)
}

@available(iOS 13.0, *)
final class URLSessionWebSocketTaskWrapper: WebSocketTask {
    var listener: WebSocketURLSessionListener? {
        get {
            urlSession.listener
        }
        set {
            urlSession.listener = newValue
        }
    }
    
    private let url: URL
    private let urlSession: WebSocketURLSession
    private var webSocketTask: URLSessionWebSocketTask
    
    init(url: URL,
         urlSession: WebSocketURLSession = WebSocketURLSessionWrapper(configuration: .default,
                                                                      delegateQueue: nil)) {
        self.url = url
        self.urlSession = urlSession
        webSocketTask = urlSession.webSocketTask(with: url)
    }
    
    var receiver: ((Result<URLSessionWebSocketTask.Message, Error>) -> Void)?
    
    func connect() {
        switch webSocketTask.state {
        case .running: break
        case .canceling, .completed:
            webSocketTask = urlSession.webSocketTask(with: url)
            fallthrough
        case .suspended:
            webSocketTask.resume()
            setReceiver()
        @unknown default: break
        }
    }
    
    private func setReceiver() {
        let handler = { [weak self] (result: Result<URLSessionWebSocketTask.Message, Error>) in
            guard let self = self else { return }
            self.receiver?(result)
            self.setReceiver()
        }

        webSocketTask.receive(completionHandler: handler)
    }
    
    func disconnect() {
        let reason = "Closing connection".data(using: .utf8)
        webSocketTask.cancel(with: .goingAway, reason: reason)
    }
    
    func send(_ message: URLSessionWebSocketTask.Message,
              completionHandler: @escaping (Error?) -> Void) {
        webSocketTask.send(message, completionHandler: completionHandler)
    }
}
