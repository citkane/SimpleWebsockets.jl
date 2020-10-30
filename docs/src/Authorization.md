# Authorization

Authorizing a client connection to a server can be achieved at two levels:
1. Http request validation
2. Websocket message challenge

## Http request validation
A user may pass a function with one parameter to the [Server Options](@ref) `authfunction`.

The parameter is of type `RequestDetails` and the function must return `Bool`.

```@docs
RequestDetails
```

## Websocket message challenge
A user may allow all clients to connect, and then allow challenge verification over websocket.

To this end, the [Websocket Connection](@ref) has a `validation` key, which contains `Dict{String, Any}`.

By default, `validation` is:
```julia
(
    "valid" => true
)
```

Setting `validation["valid"] = false` will deny the connection participation in [`emit`](@ref) and [`broadcast`](@ref) methods, but allow the server to send and receive messages to it.

**Example**
```julia
using SimpleWebsockets
server = WebsocketServer()
supersecret = "supersecret"

listen(server, :client) do client::WebsocketConnection
    client.validation["valid"] = false
    send(client, "Awaiting supersecret")
    listen(client, :message) do message
        if(!client.validation["valid"])
            message === supersecret && (client.validation["valid"] = true)
            !client.validation["valid"] && close(client, 1000, "Not authorized")
        end
    end
end

serve(server)
```