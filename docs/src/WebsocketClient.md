# Websocket Client

Provides a Websocket client compatible with Websocket versions [8, 13]

Currently does not support Websocket Extensions

Minimum required usage:
```julia
using SimpleWebsockets

client = WebsocketClient()

listen(client, :connect) do ws::WebsocketConnection #must be called before `open`
    #...
end

open(client, "ws://url.url")
```

## Constructor
```@docs
WebsocketClient
```
## Client Methods
```@docs
Base.open(::WebsocketClient, ::String)
isopen(::WebsocketClient)
```
## Client Events
Client event callback functions are registered using the `listen` method.
```@docs
listen(::Function, ::WebsocketClient, ::Symbol)
```
!!! note ":connect"
    Triggered when the client has successfully connected to the server

    Returns a [`WebsocketConnection`](@ref Websocket-Connection) to the callback.
    
    ```julia
    listen(client, :connect) do ws::SimpleWebsockets.WebsocketConnection
        #...
    end
    ```
!!! note ":connectError"
    Triggered when an attempt to open a client connection fails
    ```julia
    listen(client, :connectError) do err::WebsocketError.ConnectError
        # err.msg::String
        # err.log::Function > logs the error message with stack trace
    end
    ```

