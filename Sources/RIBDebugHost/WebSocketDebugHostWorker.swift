//
//  WebSocketDebugHostWorker.swift
//
//
//  Created by Adam Share on 8/12/20.
//

import Foundation
import UIKit
import RIBs
import RxSwift
import RxOptional

@available(iOS 13.0, *)
public final class WebSocketDebugHostWorker: Worker {
    
    public static let defaultUrl: URL = URL(string: "ws://0.0.0.0:8080")!
    
    public weak var router: Routing?
    
    private let jsonEncoder: JSONEncoder = JSONEncoder()
    private let webSocketClient: RxWebSocketClient
    private let server: DefaultWebSocketServer = DefaultWebSocketServer()
    private let monitoringTimeInterval: TimeInterval
    
    public convenience init(monitoringTimeInterval: TimeInterval = 1,
                            webSocketURL: URL = defaultUrl) {
        self.init(monitoringTimeInterval: monitoringTimeInterval,
                  webSocketClient: WebSocketClient(url: webSocketURL))
    }
    
    public init(monitoringTimeInterval: TimeInterval = 1,
                webSocketClient: RxWebSocketClient) {
        self.monitoringTimeInterval = monitoringTimeInterval
        self.webSocketClient = webSocketClient
    }
    
    public override func didStart(_ interactorScope: InteractorScope) {
        super.didStart(interactorScope)
        
        server.start()
        
        webSocketClient.connect().disposeOnStop(self)
        
        Observable<Int>.interval(.milliseconds(Int(monitoringTimeInterval * 1000)), scheduler: MainScheduler.instance)
            .map { [weak self] _ -> String? in return self?.jsonEncoder.encodeString(self?.router?.metadata()) }
            .filterNil()
            .flatMapLatest { text in
                self.webSocketClient
                    .send(text: text)
                    .asObservable()
                    .catchError { (error) -> Observable<Never> in .never()  }
        }
        .subscribe()
        .disposeOnStop(self)
    }
    
    public override func didStop() {
        super.didStop()
        
        server.stop()
    }
    
    func received(text: String) {
        DispatchQueue.main.async {
            if let data = self.router?.captureRouterView(className: text) {
                self.webSocketClient.send(data: data).subscribe().disposeOnStop(self)
            }
        }
    }
}

