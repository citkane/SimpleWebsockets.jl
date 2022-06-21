"""
    WebsocketClient([; options...])

Constructs a new WebsocketClient, overriding [`clientConfig`](@ref) with the passed options.

# Example
```julia
using SimpleWebsockets
client = WebsocketClient([; options...])
```
"""
struct WebsocketClient
    config::NamedTuple
    callbacks::Dict{Symbol, Union{Bool, Function}}
    flags::Dict{Symbol, Bool}

    function WebsocketClient(; config...)
        @debug "WebsocketClient"
        config = merge(clientConfig, (; config...))
        config = merge(config, (; maskOutgoingPackets = true, type = "client") )
        self = new(
            config,
            Dict{Symbol, Union{Bool, Function}}(
                :connect => false,
                :connectError => false,
            ),
            Dict{Symbol, Bool}(
                :isopen => false
            )
        )
    end
end
"""
    listen(callback::Function, client::SimpleWebsockets.WebsocketClient, event::Symbol)
Register event callbacks onto a client. The callback must be a function with exactly one argument.

Valid events are:
- :connect
- :connectError

# Example
```julia
listen(client, :connect) do ws
    #...
end
```
"""
function listen(
    cb::Function,
    self::WebsocketClient,
    key::Symbol   
)
    if !haskey(self.callbacks, key)
        return @warn "WebsocketClient has no listener for :$key."
    end
    if haskey(self.callbacks, key) && !(self.callbacks[key] isa Function)
        self.callbacks[key] = data -> (
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

function makeConnection(
    self::WebsocketClient,
    urlString::String,
    headers::Dict{String, String};
        options...
)
    @debug "WebsocketClient.connect"
    if isopen(self)
        @warn """called "connect" on a WebsocketClient that is open or opening."""
        return
    end
    options = merge((; options...), clientOptions)
    connected = Condition()
    self.flags[:isopen] = true
    @async try
        connection = wait(connected)
        if self.callbacks[:connect] isa Function
            self.callbacks[:connect](connection)
            wait(connection.closed)
            self.flags[:isopen] = false
        else
            throw(error("""called "open" before registering ":connect" event."""))
        end
    catch err
        err = ConnectError(err, catch_backtrace())
        self.flags[:isopen] = false
        if self.callbacks[:connectError] isa Function
            self.callbacks[:connectError](err)
        else
            err.log()
            exit()
        end
    end

    try
        headers = makeHeaders(headers)
        if !(headers["Sec-WebSocket-Version"] in ["8", "13"])
            throw(error("only version 8 and 13 of websocket protocol supported."))
        end
        if haskey(headers, "Sec-WebSocket-Extensions")
            throw(error("websocket extensions not supported in client"))
        end
        connect(
            self.config,
            urlString,
            connected,
            headers;
                options...
        )
    catch err
        @async notify(connected, err; error = true)
    end
end

function validateHandshake(headers::Dict{String, String}, request::HTTP.Messages.Response)

    if request.status != 101
        throw(error("connection error with status: $(request.status)"))
    end
    if !HTTP.hasheader(request, "Connection", "Upgrade")
        throw(error("""did not receive "Connection: Upgrade" """))
    end
    if !HTTP.hasheader(request, "Upgrade", "websocket")
        throw(error("""did not receive "Upgrade: websocket" """))
    end
    if !HTTP.hasheader(request, "Sec-WebSocket-Accept", acceptHash(headers["Sec-WebSocket-Key"]))
        throw(error("""invalid "Sec-WebSocket-Accept" response from server"""))
    end
    if HTTP.hasheader(request, "Sec-WebSocket-Extensions")
        @warn "Server uses websocket extensions" (;
            value = HTTP.header(request, "Sec-WebSocket-Extensions"),
            caution = "Websocket extensions are not supported in the client and may cause connection closure."
        )...
    end
end

function connect(
    config::NamedTuple,
    url::String,
    connected::Condition,
    headers::Dict{String, String};
        options...
)
    @debug "WebsocketClient.connect"
    let self
        HTTP.open("GET", url, headers;
            options...
        ) do io
            tcp = io.stream.io isa TCPSocket ? io.stream.io : io.stream.io.bio
            VERSION >= v"1.3" && Sockets.nagle(tcp, config.useNagleAlgorithm) #Sockets.nagle needs Julia >= 1.3
            try
                request = startread(io)
                validateHandshake(headers, request)
                self = WebsocketConnection(io.stream, config)
                notify(connected, self)
            catch err
                notify(connected, err; error = true)
                return
            end
            startConnection(self, io)
        end
    end
end
"""
    open(client::WebsocketClient, url::String [, headers::Dict{String, String}; options...])
Open a new websocket client connection at the given `url`. Blocks until the connection is closed.

Optionally provide custom `headers` for the http request.

`; options...` are passed to the underlying [HTTP.request](https://juliaweb.github.io/HTTP.jl/stable/public_interface/#Requests-1)
"""
function Base.open(client::WebsocketClient, url::String, headers::Dict{String, String} = Dict{String, String}(); options...)
    makeConnection(client, url, headers; options...)
end
"""
    isopen(client::WebsocketClient)::Bool
Returns a Bool indication if the client TCP connection is open.
"""
function Base.isopen(client::WebsocketClient)
    client.flags[:isopen]
end