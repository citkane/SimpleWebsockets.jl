"""
    WebsocketServer([; options...])

Constructs a new WebsocketServer, overriding [`serverConfig`](@ref) with the passed options.

# Example
```julia
using SimpleWebsockets
server = WebsocketServer([; options...])
```
"""
struct WebsocketServer
    config::NamedTuple
    callbacks::Dict{Symbol, Union{Bool, Function}}
    flags::Dict{Symbol, Bool}
    server::Dict{Symbol, Union{Sockets.TCPServer, Array{WebsocketConnection, 1}, Nothing}}
    location::Dict{Symbol, Union{String, Nothing, Integer}}

    function WebsocketServer(; config...)
        @debug "WebsocketServer initiate"
        config = merge(serverConfig, (; config...))
        config = merge(config, (; maskOutgoingPackets = false, type = "server",))
        self = new(
            config,
            Dict{Symbol, Union{Bool, Function}}(
                :client => false,
                :connectError => false,
                :peerError => false,
                :closed => false,
                :listening => false
            ),
            Dict{Symbol, Bool}(
                :isopen => false
            ),
            Dict{Symbol, Union{Sockets.TCPServer, Array{WebsocketConnection, 1}, Nothing}}(
                :clients => Array{WebsocketConnection, 1}(),
                :socket => nothing
            ),
            Dict{Symbol, Union{String, Nothing, Integer}}(
                :host => nothing,
                :port => nothing
            )
        )
    end

end
"""
    listen(callback::Function, server::WebsocketServer, event::Symbol)
Register event callbacks onto a server. The callback must be a function with exactly one argument.

Valid events are:
- :listening
- :client
- :connectError
- :peerError
- :closed

# Example
```julia
listen(server, :client) do client
    #...
end
```
"""
function listen(
    cb::Function,
    self::WebsocketServer,
    event::Symbol    
)
    if !haskey(self.callbacks, event)
        return @warn "WebsocketServer has no listener for :$event."
    end
    if haskey(self.callbacks, event) && !(self.callbacks[event] isa Function)
        self.callbacks[event] = data -> (
            @async try
                cb(data)
            catch err
                err = CallbackError(err, catch_backtrace())
                err.log()
                exit()
            end
        )
    end
end

function validateAuth(server::WebsocketServer, headers::HTTP.Messages.Request, queries::Dict{String,String})
    if server.config.authfunction isa Function
        headers = map(headers.headers) do header
            (Symbol(first(header)), last(header))
        end
        queries = map(collect(queries)) do query
            (Symbol(first(query)), last(query))
        end
        return server.config.authfunction(RequestDetails((; headers...),(; queries...)))
    end
    return true
end
function validateUpgrade(headers::HTTP.Messages.Request)
    if !HTTP.hasheader(headers, "Upgrade", "websocket")
        throw(error("""did not receive "Upgrade: websocket" """))
    end
    if !HTTP.hasheader(headers, "Connection", "Upgrade") && !HTTP.hasheader(headers, "Connection", "keep-alive, upgrade")
        throw(error("""did not receive "Connection: Upgrade" """))
    end
    if !HTTP.hasheader(headers, "Sec-WebSocket-Version", "13") && !HTTP.hasheader(headers, "Sec-WebSocket-Version", "8")
        throw(error("""did not receive "Sec-WebSocket-Version: [13 or 8]" """))
    end
    if !HTTP.hasheader(headers, "Sec-WebSocket-Key")
        throw(error("""did not receive "Sec-WebSocket-Key" header."""))
    end
end

"""
    serve(server::WebsocketServer, [port::Int, host::String; options...])
Opens up a TCP connection listener. Blocks while the server is listening.

Defaults:
- port: 8080
- host: "localhost"

`; options...` are passed to the underlying [HTTP.servers.listen](https://juliaweb.github.io/HTTP.jl/v1.0.2/server/#HTTP.listen)

# Example
```julia
closed = Condition()
#...
@async serve(server, 8081, "localhost")
#...
wait(closed)
```
"""
function serve(self::WebsocketServer, port::Int = 8080, host::String = "localhost"; options...)
    @debug "WebsocketServer.listen"
    config = self.config
    options = merge(serverOptions, (; options...))
    self.location[:port] = port
    self.location[:host] = host

    try
        host = getaddrinfo(host)
        if config.ssl
            tlsconfig = HTTP.Servers.SSLConfig(config.sslcert, config.sslkey)
            options = merge(options, (; sslconfig = tlsconfig))
        end
        clientcallback = self.callbacks[:client]
        clientcallback === false && throw(error("tried to bind the server before registering \":client\" handler"))
        self.server[:server] = Sockets.listen(host, port)
        
        Sockets.nagle(self.server[:server], config.useNagleAlgorithm)

        self.flags[:isopen] = true
        if self.callbacks[:listening] isa Function
            self.callbacks[:listening]((; port = port, host = host))
        end
        HTTP.listen(self.server[:server]; options...) do io
            try
                headers = io.message
                validateUpgrade(headers)
                queries = HTTP.queryparams(parse(HTTP.URI, io.message.target))
                length(queries) === 0 && (queries = Dict{String, String}())
                if !validateAuth(self, headers, queries)
                    try
                        throw(error("Invalid authorization"))
                    catch err
                        err = PeerConnectError(err, catch_backtrace())
                        errcallback = self.callbacks[:peerError]
                        if errcallback isa Function
                            errcallback(err)
                        end
                    end
                    HTTP.setstatus(io, 401)
                    startwrite(io)
                    return
                end
                HTTP.setstatus(io, 101)
                key = string(HTTP.header(headers, "Sec-WebSocket-Key"))
                HTTP.setheader(io, "Sec-WebSocket-Accept" => acceptHash(key))
                HTTP.setheader(io, "Upgrade" => "websocket")
                HTTP.setheader(io, "Connection" => "Upgrade")

                startwrite(io)
                client = WebsocketConnection(io.stream, config, self.server[:clients])
                push!(self.server[:clients], client)
                clientcallback(client)
                if HTTP.hasheader(headers, "Sec-WebSocket-Extensions")
                    @warn "Websocket extensions not implemented" header = HTTP.header(headers, "Sec-WebSocket-Extensions")
                end
                startConnection(client, io)
            catch err
                err = PeerConnectError(err, catch_backtrace())
                errcallback = self.callbacks[:peerError]
                if errcallback isa Function
                    errcallback(err)
                end
                HTTP.setstatus(io, 400)
                startwrite(io)
            end
        end
        close(self)
    catch err
        self.flags[:isopen] = false
        if typeof(err) === Base.IOError && occursin("software caused connection abort", err.msg)
            close(self)
        end
        err = ConnectError(err, catch_backtrace())
        errcallback = self.callbacks[:connectError]
        if errcallback isa Function
            errcallback(err)
        else
            err.log()
            exit()
        end
    end
end

"""
    emit(server::WebsocketServer, data::Union{Array{UInt8,1}, String, Number})
Sends the given `data` as a message to all clients connected to the server.

# Example
```julia
emit(server, "Hello everybody from your loving server.")
```
"""
function emit(self::WebsocketServer, data::Union{Array{UInt8,1}, String, Number})
    for client in self.server[:clients]
        client.validate["valid"] !== true && continue
        send(client, data)
    end
end
"""
    close(server::WebsocketServer)
Gracefully disconnects all connected clients, then closes the TCP socket listener.
"""
function Base.close(self::WebsocketServer)
    host = self.location[:host]
    port = self.location[:port]

    @sync begin
        for client in self.server[:clients]
            close(client, CLOSE_REASON_GOING_AWAY)
            @async wait(client.closed)
        end
    end
    close(self.server[:server])
    while isopen(self.server[:server])
        @warn isopen(self.server[:server])
        sleep(0.1)
    end
    self.flags[:isopen] = false
    closecallback = self.callbacks[:closed]
    if closecallback isa Function
        closecallback((; host = host, port = port))
    else
        @info "The websocket server was closed cleanly:" host = host port = port
    end
    return
end
"""
    isopen(server::WebsocketServer)::Bool
Returns a Bool indication if the server TCP listener is open.
"""
function Base.isopen(server::WebsocketServer)
    server.flags[:isopen]
end
"""
    length(server::WebsocketServer)::Int
Returns the number of clients connected to the server. 
"""
function Base.length(self::WebsocketServer)
    length(self.server[:clients])
end
