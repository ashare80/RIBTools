//
//  File.swift
//  
//
//  Created by Adam Share on 8/16/20.
//

import Foundation
import NIO
import NIOHTTP1

let websocketResponse = """
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Swift NIO WebSocket Test Page</title>
<script src="https://cdn.rawgit.com/caldwell/renderjson/master/renderjson.js"></script>
<script>
var wsconnection = new WebSocket("ws://localhost:8888/websocket");
wsconnection.onmessage = function (msg) {
var element = document.createElement("p");
element.innerHTML = msg.data;
var textDiv = document.getElementById("websocket-stream");
textDiv.append(element);
};
</script>
</head>
<body>
<h1>WebSocket Stream</h1>
<div id="websocket-stream"></div>
</body>
</html>
"""

public final class HTTPWebSocketViewHandler: ChannelInboundHandler, RemovableChannelHandler {
    public typealias InboundIn = HTTPServerRequestPart
    public typealias OutboundOut = HTTPServerResponsePart
    
    private var responseBody: ByteBuffer?
    
    public func handlerAdded(context: ChannelHandlerContext) {
        self.responseBody = context.channel.allocator.buffer(string: websocketResponse)
    }
    
    public func handlerRemoved(context: ChannelHandlerContext) {
        self.responseBody = nil
    }
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let reqPart = self.unwrapInboundIn(data)
        
        // We're not interested in request bodies here: we're just serving up GET responses
        // to get the client to initiate a websocket request.
        guard case .head(let head) = reqPart else {
            return
        }
        
        // GETs only.
        guard case .GET = head.method else {
            self.respond405(context: context)
            return
        }
        
        var headers = HTTPHeaders()
        headers.add(name: "Content-Type", value: "text/html")
        headers.add(name: "Content-Length", value: String(responseBody?.readableBytes ?? 0))
        headers.add(name: "Connection", value: "close")
        let responseHead = HTTPResponseHead(version: .init(major: 1, minor: 1),
                                            status: .ok,
                                            headers: headers)
        context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
        if let responseBody = self.responseBody {
            context.write(wrapOutboundOut(.body(.byteBuffer(responseBody))), promise: nil)
        }
        context.write(wrapOutboundOut(.end(nil))).whenComplete { (_: Result<Void, Error>) in
            context.close(promise: nil)
        }
        context.flush()
    }
    
    private func respond405(context: ChannelHandlerContext) {
        var headers = HTTPHeaders()
        headers.add(name: "Connection", value: "close")
        headers.add(name: "Content-Length", value: "0")
        let head = HTTPResponseHead(version: .init(major: 1, minor: 1),
                                    status: .methodNotAllowed,
                                    headers: headers)
        context.write(self.wrapOutboundOut(.head(head)), promise: nil)
        context.write(self.wrapOutboundOut(.end(nil))).whenComplete { (_: Result<Void, Error>) in
            context.close(promise: nil)
        }
        context.flush()
    }
}
