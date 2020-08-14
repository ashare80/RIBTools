//
//  WebSocketClient.swift
//  
//
//  Created by Adam Share on 8/12/20.
//

import Foundation
import RxSwift
import RxSwift

@available(iOS 13.0, *)
protocol WebSocketURLSessionObserving: AnyObject {
    var didOpen: Observable<String?> { get }
    var didClose: Observable<(closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?)> { get }
}

public protocol RxWebSocketClient {
    func asObservable() -> Observable<Result<URLSessionWebSocketTask.Message, Error>>
    func connect() -> Disposable
    func send(data: Data) -> Completable
    func send(text: String) -> Completable
}

@available(iOS 13.0, *)
final class WebSocketClient: ConnectableObservableType, RxWebSocketClient {
    typealias Element = Result<URLSessionWebSocketTask.Message, Error>
    
    private let webSocketTask: WebSocketTask
    private let receiverSubject: PublishSubject<Element> = PublishSubject()
    
    convenience init(url: URL) {
        self.init(webSocketTask: URLSessionWebSocketTaskWrapper(url: url))
    }
    
    init(webSocketTask: WebSocketTask) {
        self.webSocketTask = webSocketTask
        webSocketTask.listener = self
        webSocketTask.receiver = receiverSubject.onNext
    }
    
    func connect() -> Disposable {
        let webSocketTask = self.webSocketTask
        webSocketTask.connect()
        return Disposables.create {
            webSocketTask.disconnect()
        }
    }
    
    func send(data: Data) -> Completable {
        return send(event: .data(data))
    }
    
    func send(text: String) -> Completable {
        return send(event: .string(text))
    }
    
    private func send(event: URLSessionWebSocketTask.Message) -> Completable {
        return Completable.create { (observer) -> Disposable in
            self.webSocketTask.send(event) { error in
                if let error = error {
                    observer(.error(error))
                } else {
                    observer(.completed)
                }
            }
            return Disposables.create()
        }
    }
    
    func subscribe<Observer>(_ observer: Observer) -> Disposable where Observer : ObserverType, Element == Observer.Element {
        return receiverSubject.subscribe(observer)
    }
}

extension WebSocketClient: WebSocketURLSessionListener {
    func webSocketDidOpenWithProtocol(name: String?) {
        
    }
    
    func webSocketDidCloseWith(closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        
    }
}

extension ObservableType where Element == Result<URLSessionWebSocketTask.Message, Error> {
    var stringMessages: Observable<String> {
        return map { (element) -> String? in
            switch element {
            case .success(let message):
                switch message {
                case .string(let text): return text
                case .data: return nil
                @unknown default: return nil
                }
            case .failure: return nil
            }
        }
        .filterNil()
    }
    
    var dataMessages: Observable<Data> {
        return map { (element) -> Data? in
            switch element {
            case .success(let message):
                switch message {
                case .string: return nil
                case .data(let data): return data
                @unknown default: return nil
                }
            case .failure: return nil
            }
        }
        .filterNil()
    }
}
