//
//  WebSocketURLSession.swift
//  
//
//  Created by Adam Share on 8/13/20.
//

import Foundation

@available(iOS 13.0, *)
protocol WebSocketURLSession: AnyObject {
    var listener: WebSocketURLSessionListener? { get set }
    func webSocketTask(with url: URL) -> URLSessionWebSocketTask
}

@available(iOS 13.0, *)
protocol WebSocketURLSessionListener: AnyObject {
    func webSocketDidOpenWithProtocol(name: String?)
    func webSocketDidCloseWith(closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?)
}

@available(iOS 13.0, *)
final class WebSocketURLSessionWrapper: NSObject, WebSocketURLSession, URLSessionWebSocketDelegate {
    
    weak var listener: WebSocketURLSessionListener?
    
    private lazy var urlSession: URLSession = URLSession(configuration: configuration,
                            delegate: self,
                            delegateQueue: delegateQueue)
    
    private let configuration: URLSessionConfiguration
    private let delegateQueue: OperationQueue?
    
    init(configuration: URLSessionConfiguration,
         delegateQueue: OperationQueue? = nil) {
        self.configuration = configuration
        self.delegateQueue = delegateQueue
        super.init()
    }
    func webSocketTask(with url: URL) -> URLSessionWebSocketTask {
        return urlSession.webSocketTask(with: url)
    }
    
    // MARK: URLSessionWebSocketDelegate
    
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocolName: String?) {
        listener?.webSocketDidOpenWithProtocol(name: protocolName)
    }
    
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        listener?.webSocketDidCloseWith(closeCode: closeCode,
                                        reason: reason)
    }
}
