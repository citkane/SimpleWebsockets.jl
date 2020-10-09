# Client Options

Options are passed to the client at two stages:
- [`WebsocketClient`](@ref) constructor
- [`open`](@ref Base.open(::WebsocketClient, ::String)) method
```julia
using SimpleWebsockets

client = WebsocketServer([; clientOptions...])
# ...
open(client, url[, customHeaders::Dict{String, String}; socketOptions...])
```
```@meta
CurrentModule = SimpleWebsockets
```
## `clientOptions`
Overrides the default clientConfig
```@docs
clientConfig
```
## `socketOptions`
Options to pass into the underlying [HTTP.request](https://juliaweb.github.io/HTTP.jl/stable/public_interface/#Requests-1)

Handy options:
!!! note "require_ssl_verification"
    `::Bool`

    Set to `false` to work with snakeoil certs. Handy for testing.
!!! note "verbose"
    `::Int`

    Set to 0, 1 or 2.
!!! note "Basic Authentication options"
    Basic authentication is detected automatically from the provided url's userinfo 
    in the form of 
    
    `scheme://user:password@host`
    
    and adds the "Authorization: Basic" header
## Default request headers
```@docs
defaultHeaders
```
