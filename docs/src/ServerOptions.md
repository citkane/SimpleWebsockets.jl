# Server Options

Options are passed to the server at two stages:
- [`WebsocketServer`](@ref) constructor
- [`serve`](@ref) method
```julia
using SimpleWebsockets

server = WebsocketServer([; serverOptions...])
# ...
serve(server[, port, host; socketOptions...])
```
```@meta
CurrentModule = SimpleWebsockets
```
## `serverOptions`
Overrides the default serverConfig
```@docs
serverConfig
```

## socketOptions
`TCP` options to pass into the underlying [HTTP.Servers.listen](https://juliaweb.github.io/HTTP.jl/stable/public_interface/#Server-/-Handlers-1)

Handy options:
!!! note "tcpisvalid"
    Implement connection filtering 
    ```julia
        tcpisvalid::Function = tcp::Union{MbedTLS.SSLContext, Sockets.TCPSocket} -> (
            # Do your CORS, etc. logic here
            # return ::Bool
        )::Bool
    ```
!!! note "verbose"
    `::Bool`

    Turns on some helful logging.

!!! warning "sslconfig"
    Aspects of this option are behaving strangely in [HTTP.Servers.listen](https://juliaweb.github.io/HTTP.jl/stable/public_interface/#Server-/-Handlers-1)

    Please use [`serverConfig`](@ref).ssl options instead.