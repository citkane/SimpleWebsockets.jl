var documenterSearchIndex = {"docs":
[{"location":"Acknowledgments/#Acknowledgments","page":"Acknowledgments","title":"Acknowledgments","text":"","category":"section"},{"location":"Acknowledgments/","page":"Acknowledgments","title":"Acknowledgments","text":"Work on SimpleWebsockets.jl was undertaken to provide myself with familiar tool patterns I am used to using in Node.js.","category":"page"},{"location":"Acknowledgments/","page":"Acknowledgments","title":"Acknowledgments","text":"As such, this package is very much in debt to the architecture of the most excellent Node.js websocket package by theturtle32.","category":"page"},{"location":"Acknowledgments/","page":"Acknowledgments","title":"Acknowledgments","text":"Also, thanks to the team of HTTP.jl for the groundwork in bringing HTTP to Julia.","category":"page"},{"location":"Errors/#Error-Handling","page":"Error handling","title":"Error Handling","text":"","category":"section"},{"location":"Errors/","page":"Error handling","title":"Error handling","text":"Websockets are inherently asynchronous, so error handling can be inflexible.","category":"page"},{"location":"Errors/","page":"Error handling","title":"Error handling","text":"SimpleWebsockets.jl offers the user event hooks to register callbacks and handle errors flexibly.","category":"page"},{"location":"Errors/","page":"Error handling","title":"Error handling","text":"SEE: Server Events, Client Events, Connection Events","category":"page"},{"location":"Errors/","page":"Error handling","title":"Error handling","text":"If no callbacks are registered, hardcoded @info, @warn and @error calls will provide logging feedback,  but the parent process will remain unaffected by exceptions.","category":"page"},{"location":"Errors/","page":"Error handling","title":"Error handling","text":"CurrentModule = SimpleWebsockets","category":"page"},{"location":"Errors/#WebsocketError","page":"Error handling","title":"WebsocketError","text":"","category":"section"},{"location":"Errors/","page":"Error handling","title":"Error handling","text":"WebsocketError","category":"page"},{"location":"Errors/#SimpleWebsockets.WebsocketError","page":"Error handling","title":"SimpleWebsockets.WebsocketError","text":"abstract type WebsocketError <: Exception\n\nWebsocketError child error types have the following fields:\n\nmsg::String\nlog::Function\n\nThe log() function will internally call: @error msg  exception = (err, trace)\n\nWhere trace is the backtrace of the exception origin.\n\n\n\n\n\n","category":"type"},{"location":"Errors/#WebsocketError-types","page":"Error handling","title":"WebsocketError types","text":"","category":"section"},{"location":"Errors/","page":"Error handling","title":"Error handling","text":"ConnectError\nCallbackError\nFrameError","category":"page"},{"location":"Errors/#SimpleWebsockets.ConnectError","page":"Error handling","title":"SimpleWebsockets.ConnectError","text":"struct ConnectError <: WebsocketError\n\nAn exception originated while trying to start a server or connect to a server\n\n\n\n\n\n","category":"type"},{"location":"Errors/#SimpleWebsockets.CallbackError","page":"Error handling","title":"SimpleWebsockets.CallbackError","text":"struct CallbackError <: WebsocketError\n\nAn exception originated in a user provided callback function\n\n\n\n\n\n","category":"type"},{"location":"Errors/#SimpleWebsockets.FrameError","page":"Error handling","title":"SimpleWebsockets.FrameError","text":"struct FrameError <: WebsocketError\n\nAn exception originated while parsing a websocket data frame\n\n\n\n\n\n","category":"type"},{"location":"Errors/#Convenience-methods","page":"Error handling","title":"Convenience methods","text":"","category":"section"},{"location":"Errors/","page":"Error handling","title":"Error handling","text":"logWSerror\nthrowWSerror","category":"page"},{"location":"Errors/#SimpleWebsockets.logWSerror","page":"Error handling","title":"SimpleWebsockets.logWSerror","text":"logWSerror(err::Union{Exception, WebsocketError})\n\nA convenience method to lift errors into a scope and log them.\n\nExample\n\nusing SimpleWebsockets\n\nserver = WebsocketServer()\nended = Condition()\n\nlisten(server, :client) do client end\nlisten(server, :connectError) do err::WebsocketError\n    notify(ended, err)\nend\n\n@async serve(server, 8080, \"notahost\")\n\nreason = wait(ended)\nreason isa Exception && logWSerror(reason)\n\n\n\n\n\n","category":"function"},{"location":"Errors/#SimpleWebsockets.throwWSerror","page":"Error handling","title":"SimpleWebsockets.throwWSerror","text":"throwWSerror(err::Union{Exception, WebsocketError})\n\nA convenience method to lift fatal errors into a scope and throw them.\n\nExample\n\nusing SimpleWebsockets\n\nserver = WebsocketServer()\nended = Condition()\n\nlisten(server, :client) do client end\nlisten(server, :connectError) do err::WebsocketError\n    notify(ended, err)\nend\n\n@async serve(server, 8080, \"notahost\")\n\nreason = wait(ended)\nreason isa Exception && throwWSerror(reason)\n\n\n\n\n\n","category":"function"},{"location":"ServerOptions/#Server-Options","page":"Server Options","title":"Server Options","text":"","category":"section"},{"location":"ServerOptions/","page":"Server Options","title":"Server Options","text":"Options are passed to the server at two stages:","category":"page"},{"location":"ServerOptions/","page":"Server Options","title":"Server Options","text":"WebsocketServer constructor\nserve method","category":"page"},{"location":"ServerOptions/","page":"Server Options","title":"Server Options","text":"using SimpleWebsockets\n\nserver = WebsocketServer([; serverOptions...])\n# ...\nserve(server[, port, host; socketOptions...])","category":"page"},{"location":"ServerOptions/","page":"Server Options","title":"Server Options","text":"CurrentModule = SimpleWebsockets","category":"page"},{"location":"ServerOptions/#serverOptions","page":"Server Options","title":"serverOptions","text":"","category":"section"},{"location":"ServerOptions/","page":"Server Options","title":"Server Options","text":"Overrides the default serverConfig","category":"page"},{"location":"ServerOptions/","page":"Server Options","title":"Server Options","text":"serverConfig","category":"page"},{"location":"ServerOptions/#SimpleWebsockets.serverConfig","page":"Server Options","title":"SimpleWebsockets.serverConfig","text":"The default options for WebsocketServer\n\ninfo: ssl\n[false]::BoolWhether to use ssl on the server.warning: Warning\nDue to an underlying issue in HTTP, a client calling ws:// on a wss:://  server will cause the server to error and close. Ensure that only ssl traffic can reach your server port.\n\ninfo: sslcert\n[../src/etc/snakeoil.crt in the SimpleWebsockets module dir]::StringAbsolute path to your ssl cert\n\ninfo: sslkey\n[../src/etc/snakeoil.key in the SimpleWebsockets module dir]::StringAbsolute path to your ssl key\n\ninfo: maxReceivedFrameSize\n[64 * 0x0400 = 64KiB]::IntegerThe maximum frame size that the server will accept\n\ninfo: maxReceivedMessageSize\n[1 * 0x100000 = 1MiB]::IntegerThe maximum assembled message size that the server will accept\n\ninfo: fragmentOutgoingMessages\n[true]::BoolOutgoing frames are fragmented if they exceed the set threshold.\n\ninfo: fragmentationThreshold\n[16 * 0x0400 = 16KiB]::IntegerOutgoing frames are fragmented if they exceed this threshold.\n\ninfo: closeTimeout\n[5]::IntThe number of seconds to wait after sending a close frame for an acknowledgement to return from the client. Will force close the client if timed out.\n\ninfo: keepaliveTimeout\n[20]::Union{Int, Bool}The interval in number of seconds to solicit each client with a ping / pong response. The client will be closed if no pong is received within the interval.The timer is only active when no data is received from the client within the interval, ie. the client will only be pinged if inactive for a period longer than the interval.false to disable.warning: Warning\nDue to an underlying issue with HTTP,  a server network disconnect will cause all clients to block in their listen loop,  only registering disconnect when the network re-connects.keepaliveTimeout uses ping/pong and will register the client disconnects more efficiently in network outage events.\n\ninfo: useNagleAlgorithm\n[false]::BoolThe Nagle Algorithm makes more efficient use of network resources by introducing a small delay before sending small packets so that multiple messages can be batched together before going onto the wire.  This however comes at the cost of latency, so the default is to disable it.  If you don't need low latency and are streaming lots of small messages, you can change this to trueinfo: Julia 1.3\nThis setting only has an affect as of Julia 1.3\n\ninfo: binary\n[false]::BoolUse Array{UInt8, 1} instead of String as messaging format.\n\n\n\n\n\n","category":"constant"},{"location":"ServerOptions/#socketOptions","page":"Server Options","title":"socketOptions","text":"","category":"section"},{"location":"ServerOptions/","page":"Server Options","title":"Server Options","text":"TCP options to pass into the underlying HTTP.Servers.listen","category":"page"},{"location":"ServerOptions/","page":"Server Options","title":"Server Options","text":"Handy options:","category":"page"},{"location":"ServerOptions/","page":"Server Options","title":"Server Options","text":"note: tcpisvalid\nImplement connection filtering     tcpisvalid::Function = tcp::Union{MbedTLS.SSLContext, Sockets.TCPSocket} -> (\n        # Do your CORS, etc. logic here\n        # return ::Bool\n    )::Bool","category":"page"},{"location":"ServerOptions/","page":"Server Options","title":"Server Options","text":"note: verbose\n::BoolTurns on some helful logging.","category":"page"},{"location":"ServerOptions/","page":"Server Options","title":"Server Options","text":"warning: sslconfig\nAspects of this option are behaving strangely in HTTP.Servers.listenPlease use serverConfig.ssl options instead.","category":"page"},{"location":"WebsocketClient/#Websocket-Client","page":"Client Usage","title":"Websocket Client","text":"","category":"section"},{"location":"WebsocketClient/","page":"Client Usage","title":"Client Usage","text":"Provides a Websocket client compatible with Websocket versions [8, 13]","category":"page"},{"location":"WebsocketClient/","page":"Client Usage","title":"Client Usage","text":"Currently does not support Websocket Extensions","category":"page"},{"location":"WebsocketClient/","page":"Client Usage","title":"Client Usage","text":"Minimum required usage:","category":"page"},{"location":"WebsocketClient/","page":"Client Usage","title":"Client Usage","text":"using SimpleWebsockets\n\nclient = WebsocketClient()\n\nlisten(client, :connect) do ws::WebsocketConnection #must be called before `open`\n    #...\nend\n\nopen(client, \"ws://url.url\")","category":"page"},{"location":"WebsocketClient/#Constructor","page":"Client Usage","title":"Constructor","text":"","category":"section"},{"location":"WebsocketClient/","page":"Client Usage","title":"Client Usage","text":"WebsocketClient","category":"page"},{"location":"WebsocketClient/#SimpleWebsockets.WebsocketClient","page":"Client Usage","title":"SimpleWebsockets.WebsocketClient","text":"WebsocketClient([; options...])\n\nConstructs a new WebsocketClient, overriding clientConfig with the passed options.\n\nExample\n\nusing SimpleWebsockets\nclient = WebsocketClient([; options...])\n\n\n\n\n\n","category":"type"},{"location":"WebsocketClient/#Client-Methods","page":"Client Usage","title":"Client Methods","text":"","category":"section"},{"location":"WebsocketClient/","page":"Client Usage","title":"Client Usage","text":"Base.open(::WebsocketClient, ::String)\nisopen(::WebsocketClient)","category":"page"},{"location":"WebsocketClient/#Base.open-Tuple{WebsocketClient,String}","page":"Client Usage","title":"Base.open","text":"open(client::WebsocketClient, url::String [, headers::Dict{String, String}; options...])\n\nOpen a new websocket client connection at the given url. Blocks until the connection is closed.\n\nOptionally provide custom headers for the http request.\n\n; options... are passed to the underlying HTTP.request\n\n\n\n\n\n","category":"method"},{"location":"WebsocketClient/#Base.isopen-Tuple{WebsocketClient}","page":"Client Usage","title":"Base.isopen","text":"isopen(client::WebsocketClient)::Bool\n\nReturns a Bool indication if the client TCP connection is open.\n\n\n\n\n\n","category":"method"},{"location":"WebsocketClient/#Client-Events","page":"Client Usage","title":"Client Events","text":"","category":"section"},{"location":"WebsocketClient/","page":"Client Usage","title":"Client Usage","text":"Client event callback functions are registered using the listen method.","category":"page"},{"location":"WebsocketClient/","page":"Client Usage","title":"Client Usage","text":"listen(::Function, ::WebsocketClient, ::Symbol)","category":"page"},{"location":"WebsocketClient/#Sockets.listen-Tuple{Function,WebsocketClient,Symbol}","page":"Client Usage","title":"Sockets.listen","text":"listen(callback::Function, client::SimpleWebsockets.WebsocketClient, event::Symbol)\n\nRegister event callbacks onto a client. The callback must be a function with exactly one argument.\n\nValid events are:\n\n:connect\n:connectError\n\nExample\n\nlisten(client, :connect) do ws\n    #...\nend\n\n\n\n\n\n","category":"method"},{"location":"WebsocketClient/","page":"Client Usage","title":"Client Usage","text":"note: :connect\nTriggered when the client has successfully connected to the serverReturns a WebsocketConnection to the callback.listen(client, :connect) do ws::SimpleWebsockets.WebsocketConnection\n    #...\nend","category":"page"},{"location":"WebsocketClient/","page":"Client Usage","title":"Client Usage","text":"note: :connectError\nTriggered when an attempt to open a client connection failslisten(client, :connectError) do err::WebsocketError.ConnectError\n    # err.msg::String\n    # err.log::Function > logs the error message with stack trace\nend","category":"page"},{"location":"WebsocketServer/#WebsocketServer","page":"Server Usage","title":"WebsocketServer","text":"","category":"section"},{"location":"WebsocketServer/","page":"Server Usage","title":"Server Usage","text":"Provides a Websocket server compatible with Websocket versions [8, 13]","category":"page"},{"location":"WebsocketServer/","page":"Server Usage","title":"Server Usage","text":"Currently does not support Websocket Extensions","category":"page"},{"location":"WebsocketServer/","page":"Server Usage","title":"Server Usage","text":"Minimum required usage:","category":"page"},{"location":"WebsocketServer/","page":"Server Usage","title":"Server Usage","text":"using SimpleWebsockets\n\nserver = WebsocketServer()\n\nlisten(server, :client) do client::WebsocketConnection #must be called before `serve`\n    #...\nend\nserve(server)","category":"page"},{"location":"WebsocketServer/#Constructor","page":"Server Usage","title":"Constructor","text":"","category":"section"},{"location":"WebsocketServer/","page":"Server Usage","title":"Server Usage","text":"WebsocketServer","category":"page"},{"location":"WebsocketServer/#SimpleWebsockets.WebsocketServer","page":"Server Usage","title":"SimpleWebsockets.WebsocketServer","text":"WebsocketServer([; options...])\n\nConstructs a new WebsocketServer, overriding serverConfig with the passed options.\n\nExample\n\nusing SimpleWebsockets\nserver = WebsocketServer([; options...])\n\n\n\n\n\n","category":"type"},{"location":"WebsocketServer/#Server-Methods","page":"Server Usage","title":"Server Methods","text":"","category":"section"},{"location":"WebsocketServer/","page":"Server Usage","title":"Server Usage","text":"serve\nemit\nclose(::WebsocketServer)\nisopen(::WebsocketServer)\nlength(::WebsocketServer)","category":"page"},{"location":"WebsocketServer/#SimpleWebsockets.serve","page":"Server Usage","title":"SimpleWebsockets.serve","text":"serve(server::WebsocketServer, [port::Int, host::String; options...])\n\nOpens up a TCP connection listener. Blocks while the server is listening.\n\nDefaults:\n\nport: 8080\nhost: \"localhost\"\n\n; options... are passed to the underlying HTTP.servers.listen\n\nExample\n\nclosed = Condition()\n#...\n@async serve(server, 8081, \"localhost\")\n#...\nwait(closed)\n\n\n\n\n\n","category":"function"},{"location":"WebsocketServer/#SimpleWebsockets.emit","page":"Server Usage","title":"SimpleWebsockets.emit","text":"emit(server::WebsocketServer, data::Union{Array{UInt8,1}, String, Number})\n\nSends the given data as a message to all clients connected to the server.\n\nExample\n\nemit(server, \"Hello everybody from your loving server.\")\n\n\n\n\n\n","category":"function"},{"location":"WebsocketServer/#Base.close-Tuple{WebsocketServer}","page":"Server Usage","title":"Base.close","text":"close(server::WebsocketServer)\n\nGracefully disconnects all connected clients, then closes the TCP socket listener.\n\n\n\n\n\n","category":"method"},{"location":"WebsocketServer/#Base.isopen-Tuple{WebsocketServer}","page":"Server Usage","title":"Base.isopen","text":"isopen(server::WebsocketServer)::Bool\n\nReturns a Bool indication if the server TCP listener is open.\n\n\n\n\n\n","category":"method"},{"location":"WebsocketServer/#Base.length-Tuple{WebsocketServer}","page":"Server Usage","title":"Base.length","text":"length(server::WebsocketServer)::Int\n\nReturns the number of clients connected to the server. \n\n\n\n\n\n","category":"method"},{"location":"WebsocketServer/#Server-Events","page":"Server Usage","title":"Server Events","text":"","category":"section"},{"location":"WebsocketServer/","page":"Server Usage","title":"Server Usage","text":"Server event callback functions are registered using the listen method.","category":"page"},{"location":"WebsocketServer/","page":"Server Usage","title":"Server Usage","text":"listen(::Function, ::WebsocketServer, ::Symbol)","category":"page"},{"location":"WebsocketServer/#Sockets.listen-Tuple{Function,WebsocketServer,Symbol}","page":"Server Usage","title":"Sockets.listen","text":"listen(callback::Function, server::WebsocketServer, event::Symbol)\n\nRegister event callbacks onto a server. The callback must be a function with exactly one argument.\n\nValid events are:\n\n:listening\n:client\n:connectError\n:closed\n\nExample\n\nlisten(server, :client) do client\n    #...\nend\n\n\n\n\n\n","category":"method"},{"location":"WebsocketServer/","page":"Server Usage","title":"Server Usage","text":"note: :listening\nTriggered when the server TCP socket openslisten(server, :listening) do details::NamedTuple\n    # details.port::Int\n    # details.host::Union{Sockets.IPv4, Sockets.IPv6}\nend","category":"page"},{"location":"WebsocketServer/","page":"Server Usage","title":"Server Usage","text":"note: :client\nTriggered when a client connects to the serverReturns a WebsocketConnection to the callback.listen(server, :client) do client::SimpleWebsockets.WebsocketConnection\n    # ...\nend","category":"page"},{"location":"WebsocketServer/","page":"Server Usage","title":"Server Usage","text":"note: :connectError\nTriggered when an attempt to open a TCP socket listener failslisten(server, :connectError) do err::WebsocketError.ConnectError\n    # err.msg::String\n    # err.log::Function > logs the error message with stack trace\nend","category":"page"},{"location":"WebsocketServer/","page":"Server Usage","title":"Server Usage","text":"note: :closed\nTriggered when the server TCP socket closeslisten(server, :closed) do details::NamedTuple\n    # details.port::Int\n    # details.host::Union{Sockets.IPv4, Sockets.IPv6}\nend","category":"page"},{"location":"ClientOptions/#Client-Options","page":"Client Options","title":"Client Options","text":"","category":"section"},{"location":"ClientOptions/","page":"Client Options","title":"Client Options","text":"Options are passed to the client at two stages:","category":"page"},{"location":"ClientOptions/","page":"Client Options","title":"Client Options","text":"WebsocketClient constructor\nopen method","category":"page"},{"location":"ClientOptions/","page":"Client Options","title":"Client Options","text":"using SimpleWebsockets\n\nclient = WebsocketServer([; clientOptions...])\n# ...\nopen(client, url[, customHeaders::Dict{String, String}; socketOptions...])","category":"page"},{"location":"ClientOptions/","page":"Client Options","title":"Client Options","text":"CurrentModule = SimpleWebsockets","category":"page"},{"location":"ClientOptions/#clientOptions","page":"Client Options","title":"clientOptions","text":"","category":"section"},{"location":"ClientOptions/","page":"Client Options","title":"Client Options","text":"Overrides the default clientConfig","category":"page"},{"location":"ClientOptions/","page":"Client Options","title":"Client Options","text":"clientConfig","category":"page"},{"location":"ClientOptions/#SimpleWebsockets.clientConfig","page":"Client Options","title":"SimpleWebsockets.clientConfig","text":"The default options for WebsocketClient\n\ninfo: maxReceivedFrameSize\n[1 * 0x100000 = 1MiB]::IntegerThe maximum frame size that the client will accept\n\ninfo: maxReceivedMessageSize\n[8 * 0x100000 = 8MiB]::IntegerThe maximum assembled message size that the client will accept\n\ninfo: fragmentOutgoingMessages\n[true]::BoolOutgoing frames are fragmented if they exceed the set threshold.\n\ninfo: fragmentationThreshold\n[16 * 0x0400 = 16KiB]::IntegerOutgoing frames are fragmented if they exceed this threshold.\n\ninfo: closeTimeout\n[5]::IntThe number of seconds to wait after sending a close frame for an acknowledgement to return from the server. Will force close the connection if timed out.\n\ninfo: keepaliveTimeout\n[1]::Union{Int, Bool}The interval in number of seconds to solicit the server with a ping / pong response. The connection will be closed if no pong is received within the interval.The timer is only active when no data is received from the server within the interval, ie. the server will only be pinged if inactive for a period longer than the interval.false to disable.warning: Warning\nDue to an underlying issue with HTTP,  a client network disconnect will cause the connection to block in it's listen loop,  only registering disconnect when the network re-connects.keepaliveTimeout uses ping/pong and will register a disconnect more efficiently in network outage events.\n\ninfo: useNagleAlgorithm\n[false]::BoolThe Nagle Algorithm makes more efficient use of network resources by introducing a small delay before sending small packets so that multiple messages can be batched together before going onto the wire.  This however comes at the cost of latency, so the default is to disable it.  If you don't need low latency and are streaming lots of small messages, you can change this to trueinfo: Julia 1.3\nThis setting only has an affect as of Julia 1.3\n\ninfo: binary\n[false]::BoolUse Array{UInt8, 1} instead of String as messaging format.\n\n\n\n\n\n","category":"constant"},{"location":"ClientOptions/#socketOptions","page":"Client Options","title":"socketOptions","text":"","category":"section"},{"location":"ClientOptions/","page":"Client Options","title":"Client Options","text":"Options to pass into the underlying HTTP.request","category":"page"},{"location":"ClientOptions/","page":"Client Options","title":"Client Options","text":"Handy options:","category":"page"},{"location":"ClientOptions/","page":"Client Options","title":"Client Options","text":"note: require_ssl_verification\n::BoolSet to false to work with snakeoil certs. Handy for testing.","category":"page"},{"location":"ClientOptions/","page":"Client Options","title":"Client Options","text":"note: verbose\n::IntSet to 0, 1 or 2.","category":"page"},{"location":"ClientOptions/","page":"Client Options","title":"Client Options","text":"note: Basic Authentication options\nBasic authentication is detected automatically from the provided url's userinfo  in the form of scheme://user:password@hostand adds the \"Authorization: Basic\" header","category":"page"},{"location":"ClientOptions/#Default-request-headers","page":"Client Options","title":"Default request headers","text":"","category":"section"},{"location":"ClientOptions/","page":"Client Options","title":"Client Options","text":"defaultHeaders","category":"page"},{"location":"ClientOptions/#SimpleWebsockets.defaultHeaders","page":"Client Options","title":"SimpleWebsockets.defaultHeaders","text":"defaultHeaders::Dict{String, String}\n\nThe default headers passed to a http upgrade request\n\nDict{String, String}(\n    \"Sec-WebSocket-Version\" => \"13\",\n    \"Upgrade\" => \"websocket\",\n    \"Connection\" => \"Upgrade\",\n    \"Sec-WebSocket-Key\" => \"\", #new key made for every request\n)\n\n\n\n\n\n","category":"constant"},{"location":"#SimpleWebsockets.jl","page":"Introduction","title":"SimpleWebsockets.jl","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"(Image: Build Status) (Image: Coverage Status) (Image: ) (Image: ) (Image: GitHub Repo stars)","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"A flexible, powerful, high level interface for Websockets in Julia. Provides a SERVER and CLIENT.","category":"page"},{"location":"#Basic-example-for-SERVER","page":"Introduction","title":"Basic example for SERVER","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"using SimpleWebsockets\n\nserver = WebsocketServer()\nended = Condition() \n\nlisten(server, :client) do client\n    listen(client, :message) do message\n        @info \"Got a message\" client = client.id message = message\n        send(client, \"Echo back at you: $message\")\n    end\nend\nlisten(server, :connectError) do err\n    logWSerror(err)\n    notify(ended, err.msg, error = true)\nend\nlisten(server, :closed) do details\n    @warn \"Server has closed\" details...\n    notify(ended)\nend\n\n@async serve(server; verbose = true)\nwait(ended)","category":"page"},{"location":"#Basic-example-for-CLIENT","page":"Introduction","title":"Basic example for CLIENT","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"using SimpleWebsockets\n\nclient = WebsocketClient()\nended = Condition()\n\nlisten(client, :connect) do ws\n    listen(ws, :message) do message\n        @info message\n    end\n    listen(ws, :close) do reason\n        @warn \"Websocket connection closed\" reason...\n        notify(ended)\n    end\n    for count = 1:10\n        send(ws, \"hello $count\")\n        sleep(1)\n    end\n    close(ws)\nend\nlisten(client, :connectError) do err\n    logWSerror(err)\n    notify(ended, err.msg, error = true)\nend\n\n@async open(client, \"ws://localhost:8080\")\nwait(ended)","category":"page"},{"location":"WebsocketConnection/#Websocket-Connection","page":"Websocket Connection","title":"Websocket Connection","text":"","category":"section"},{"location":"WebsocketConnection/","page":"Websocket Connection","title":"Websocket Connection","text":"A WebsocketConnection type is not directly constructed by the user. it can exist in two contexts:","category":"page"},{"location":"WebsocketConnection/","page":"Websocket Connection","title":"Websocket Connection","text":"SERVER listen :client event.\nCLIENT listen :connect event.","category":"page"},{"location":"WebsocketConnection/","page":"Websocket Connection","title":"Websocket Connection","text":"Typical SERVER:","category":"page"},{"location":"WebsocketConnection/","page":"Websocket Connection","title":"Websocket Connection","text":"using SimpleWebsockets\n\nserver = WebsocketServer()\nlisten(server, :client) do client::WebsocketConnection\n    # do logic with the `WebsocketConnection`\nend\nserve(server)","category":"page"},{"location":"WebsocketConnection/","page":"Websocket Connection","title":"Websocket Connection","text":"Typical CLIENT","category":"page"},{"location":"WebsocketConnection/","page":"Websocket Connection","title":"Websocket Connection","text":"using SimpleWebsockets\n\nclient = WebsocketClient()\nlisten(client, :connect) do ws::WebsocketConnection\n    # do logic with the `WebsocketConnection`\nend\nopen(client, \"ws://url.url\")","category":"page"},{"location":"WebsocketConnection/#WebsocketConnection-Methods","page":"Websocket Connection","title":"WebsocketConnection Methods","text":"","category":"section"},{"location":"WebsocketConnection/","page":"Websocket Connection","title":"Websocket Connection","text":"send\nbroadcast(::WebsocketConnection, ::Union{Array{UInt8,1}, String, Number})\nping\nclose(::WebsocketConnection, ::Int, ::String)","category":"page"},{"location":"WebsocketConnection/#SimpleWebsockets.send","page":"Websocket Connection","title":"SimpleWebsockets.send","text":"send(ws::WebsocketConnection, data::Union{String, Number, Array{UInt8,1}})\n\nSend the given data as a message over the wire.\n\n\n\n\n\n","category":"function"},{"location":"WebsocketConnection/#Base.Broadcast.broadcast-Tuple{WebsocketConnection,Union{Array{UInt8,1}, Number, String}}","page":"Websocket Connection","title":"Base.Broadcast.broadcast","text":"broadcast(client::WebsocketConnection, data::Union{Array{UInt8,1}, String, Number})\n\nsend the given data as a message to all connected clients, except the given client.\n\nIn a SERVER context, to communicate with all clients on the SERVER, use emit\n\nOnly used if the client is in a SERVER context, otherwise NOOP.\n\n\n\n\n\n","category":"method"},{"location":"WebsocketConnection/#SimpleWebsockets.ping","page":"Websocket Connection","title":"SimpleWebsockets.ping","text":"ping(ws::WebsocketConnection, data::Union{String, Number})\n\nSend data as ping message to the ws peer.\n\ndata is limited to 125Bytes, and will automatically be truncated if over this limit.\n\n\n\n\n\n","category":"function"},{"location":"WebsocketConnection/#Base.close-Tuple{WebsocketConnection,Int64,String}","page":"Websocket Connection","title":"Base.close","text":"close(ws::WebsocketConnection [, reasonCode::Int, description::String])\n\nCloses a websocket connection.\n\nSends the close frame to the peer, waits for the response close frame,  or times out on closeTimeout before closing the underlying TCP stream.\n\nOptional reasonCode must be a valid rfc6455 code,  suitable for sending over the wire.\n\nDefaults: 1000 : \"Normal connection closure\"\n\n\n\n\n\n","category":"method"},{"location":"WebsocketConnection/#WebsocketConnection-Events","page":"Websocket Connection","title":"WebsocketConnection Events","text":"","category":"section"},{"location":"WebsocketConnection/","page":"Websocket Connection","title":"Websocket Connection","text":"WebsocketConnection event callback functions are registered using the listen method.","category":"page"},{"location":"WebsocketConnection/","page":"Websocket Connection","title":"Websocket Connection","text":"listen(::Function, ::WebsocketConnection, ::Symbol)","category":"page"},{"location":"WebsocketConnection/#Sockets.listen-Tuple{Function,WebsocketConnection,Symbol}","page":"Websocket Connection","title":"Sockets.listen","text":"listen(callback::Function, ws::SimpleWebsockets.WebsocketConnection, event::Symbol)\n\nRegister event callbacks onto a WebsocketConnection. The callback must be a function with exactly one argument.\n\nValid events are:\n\n:message\n:pong\n:error\n:close\n\nExample\n\nlisten(ws::WebsocketConnection, :message) do message\n    #...\nend\n\n\n\n\n\n","category":"method"},{"location":"WebsocketConnection/","page":"Websocket Connection","title":"Websocket Connection","text":"note: :message\nTriggered when the TCP stream receives a messagelisten(ws::WebsocketConnection, :message) do message::Union{String, Array{UInt8, 1}}\n    #...\nend","category":"page"},{"location":"WebsocketConnection/","page":"Websocket Connection","title":"Websocket Connection","text":"note: :pong\nTriggered when the TCP stream receives a pong responselisten(ws::WebsocketConnection, :pong) do message::Union{String, Array{UInt8, 1}}\n    #...\nend","category":"page"},{"location":"WebsocketConnection/","page":"Websocket Connection","title":"Websocket Connection","text":"note: :error\nTriggered when an error occurs during data processinglisten(ws::WebsocketConnection, :error) do err::Union{WebsocketError.FrameError, WebsocketError.CallbackError}\n    # err.msg::String\n    # err.log::Function > logs the error message with stack trace\nend","category":"page"},{"location":"WebsocketConnection/","page":"Websocket Connection","title":"Websocket Connection","text":"note: :close\nTriggered when the underlying TCP stream has closedlisten(ws::WebsocketConnection, :close) do reason::NamedTuple\n    # reason.code::Int\n    # reason.description::String\nend","category":"page"}]
}
