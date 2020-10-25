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

    Example using [Sockets.getpeername](https://docs.julialang.org/en/v1.5/stdlib/Sockets/#Sockets.getpeername): 
    ```julia
        using SimpleWebsockets, Sockets
        function tcpisvalid(tcp::Union{MbedTLS.SSLContext, Sockets.TCPSocket})::Bool
            local ipaddress
            try
                ipaddress = Sockets.getpeername(tcp)
            catch
                ipaddress = Sockets.getpeername(tcp.bio) # for MbedTLS.SSLContext
            end
            # (ip"127.0.0.1", 0xd940)
            # Do your CORS, rate filtering, etc. logic here
            # return ::Bool
        end
        serve(server; tcpisvalid = tcpisvalid)
    ```
!!! note "verbose"
    `::Bool`

    Turns on some helful logging.
    !!! warning
        This uses the the underlying `HTTP` mechanism, which has been observed to misreport the port number.
!!! warning "sslconfig"
    Aspects of this option are behaving strangely in [HTTP.Servers.listen](https://juliaweb.github.io/HTTP.jl/stable/public_interface/#Server-/-Handlers-1)

    Please use [`serverConfig`](@ref).ssl options instead.