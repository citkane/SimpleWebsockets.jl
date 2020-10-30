# WebsocketServer
Provides a Websocket server compatible with Websocket versions [8, 13]

Currently does not support Websocket Extensions

Minimum required usage:
```julia
using SimpleWebsockets

server = WebsocketServer()

listen(server, :client) do client::WebsocketConnection #must be called before `serve`
    #...
end
serve(server)
```

## Constructor
```@docs
WebsocketServer
```
## Server Methods
```@docs
serve
emit
close(::WebsocketServer)
isopen(::WebsocketServer)
length(::WebsocketServer)
```
## Server Events
Server event callback functions are registered using the `listen` method.
```@docs
listen(::Function, ::WebsocketServer, ::Symbol)
```
!!! note ":listening"
    Triggered when the server TCP socket opens
    ```julia
    listen(server, :listening) do details::NamedTuple
        # details.port::Int
        # details.host::Union{Sockets.IPv4, Sockets.IPv6}
    end
    ```
!!! note ":client"
    Triggered when a client connects to the server

    Returns a [`WebsocketConnection`](@ref Websocket-Connection) to the callback.

    ```julia
    listen(server, :client) do client::SimpleWebsockets.WebsocketConnection
        # ...
    end
    ```
!!! note ":connectError"
    Triggered when an attempt to open a TCP socket listener fails
    ```julia
    listen(server, :connectError) do err::WebsocketError.ConnectError
        # err.msg::String
        # err.log::Function > logs the error message with stack trace
    end
    ```
!!! note ":peerError"
    Triggered when a client tries to connect with bad conditions, eg. invalid headers
    ```julia
    listen(server, :peerError) do err::WebsocketError.PeerConnectError
        # err.msg::String
        # err.log::Function > logs the error message with stack trace
    end
    ```
!!! note ":closed"
    Triggered when the server TCP socket closes
    ```julia
    listen(server, :closed) do details::NamedTuple
        # details.port::Int
        # details.host::Union{Sockets.IPv4, Sockets.IPv6}
    end
    ```