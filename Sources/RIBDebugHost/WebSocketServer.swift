//
//  File.swift
//  
//
//  Created by Adam Share on 8/14/20.
//

import Foundation
import NIO
import NIOHTTP1
import NIOWebSocket

public typealias DefaultWebSocketServer = WebSocketServer<HTTPWebSocketViewHandler, WebSocketTimeHandler>

extension DefaultWebSocketServer {
    convenience init() {
        self.init(httpHandler: HTTPWebSocketViewHandler(), websocketHandler: WebSocketTimeHandler())
    }
}

public final class WebSocketServer<HTTPHandler: ChannelInboundHandler & RemovableChannelHandler, WebSocketHandler: ChannelInboundHandler> {
    
    private let host: String
    private let httpHandler: HTTPHandler
    private let port: Int
    private let websocketHandler: WebSocketHandler
    private var channel: Channel?
    private var group: MultiThreadedEventLoopGroup?
    private let queue = DispatchQueue(label: "com.RIBTools.websocket", qos: .background)
    
    init(host: String = "localhost",
         httpHandler: HTTPHandler,
         port: Int = 8888,
         websocketHandler: WebSocketHandler) {
        self.host = host
        self.httpHandler = httpHandler
        self.port = port
        self.websocketHandler = websocketHandler
    }
    
    public func start() {
        queue.async(execute: open)
    }
    
    public func stop() {
        queue.async(execute: close)
    }

    private func open() {
        if channel != nil {
            close()
        }
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.group = group
        let websocketHandler = self.websocketHandler
        let httpHandler = self.httpHandler
        
        let upgrader = NIOWebSocketServerUpgrader(shouldUpgrade: { (channel: Channel, head: HTTPRequestHead) in
            channel.eventLoop.makeSucceededFuture(HTTPHeaders())
        },
                                                  upgradePipelineHandler: { (channel: Channel, _: HTTPRequestHead) in
                                                    channel.pipeline.addHandler(websocketHandler)
        })

        self.channel = try? ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            
            // Set the handlers that are applied to the accepted Channels
            .childChannelInitializer { channel in
                let pipeline = channel.pipeline
                //                let config: NIOHTTPServerUpgradeConfiguration =
                let add = { pipeline.addHandler(httpHandler) }
                let remove:  (ChannelHandlerContext) -> Void = { _ in pipeline.removeHandler(httpHandler, promise: nil) }
                return pipeline.configureHTTPServerPipeline(withServerUpgrade: (upgraders: [upgrader],
                                                                                completionHandler: remove))
                    .flatMap(add)
        }
            // Enable SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .bind(host: host, port: port)
            .wait()
    }
    
    private func close() {
        channel?.close(mode: .all, promise: nil)
        try? group?.syncShutdownGracefully()
        channel = nil
        group = nil
    }
}
