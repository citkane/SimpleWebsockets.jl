# Websocket Connection
A `WebsocketConnection` type is not directly constructed by the user. it can exist in two contexts:
- SERVER [`listen`](@ref listen(::Function, ::WebsocketServer, ::Symbol)) `:client` event.
- CLIENT [`listen`](@ref listen(::Function, ::WebsocketClient, ::Symbol)) `:connect` event.
Typical SERVER:
```julia
using SimpleWebsockets

server = WebsocketServer()
listen(server, :client) do client::WebsocketConnection
    # do logic with the `WebsocketConnection`
end
serve(server)
```
Typical CLIENT
```julia
using SimpleWebsockets

client = WebsocketClient()
listen(client, :connect) do ws::WebsocketConnection
    # do logic with the `WebsocketConnection`
end
open(client, "ws://url.url")
```
## `WebsocketConnection` Methods
```@docs
send
broadcast(::WebsocketConnection, ::Union{Array{UInt8,1}, String, Number})
ping
close(::WebsocketConnection, ::Int, ::String)
```
## `WebsocketConnection` Events
`WebsocketConnection` event callback functions are registered using the `listen` method.
```@docs
listen(::Function, ::WebsocketConnection, ::Symbol)
```
!!! note ":message"
    Triggered when the TCP stream receives a message
    ```julia
    listen(ws::WebsocketConnection, :message) do message::Union{String, Array{UInt8, 1}}
        #...
    end
    ```
!!! note ":pong"
    Triggered when the TCP stream receives a pong response
    ```julia
    listen(ws::WebsocketConnection, :pong) do message::Union{String, Array{UInt8, 1}}
        #...
    end
    ```
!!! note ":error"
    Triggered when an error occurs during data processing
    ```julia
    listen(ws::WebsocketConnection, :error) do err::Union{WebsocketError.FrameError, WebsocketError.CallbackError}
        # err.msg::String
        # err.log::Function > logs the error message with stack trace
    end
    ```
!!! note ":close"
    Triggered when the underlying TCP stream has closed
    ```julia
    listen(ws::WebsocketConnection, :close) do reason::NamedTuple
        # reason.code::Int
        # reason.description::String
    end
    ```