# SimpleWebsockets.jl 
[![CI](https://github.com/citkane/SimpleWebsockets.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/citkane/SimpleWebsockets.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![codecov](https://codecov.io/gh/citkane/SimpleWebsockets.jl/branch/master/graph/badge.svg?token=6TDC0TA25F)](https://codecov.io/gh/citkane/SimpleWebsockets.jl)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://citkane.github.io/SimpleWebsockets.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://citkane.github.io/SimpleWebsockets.jl/dev)

A flexible, powerful, high level interface for Websockets in Julia. Provides a SERVER and CLIENT.

## Release 0.3 notes
0.3 upgrades the "HTTP" package dependency to major version 1
This breaks all functionality for Julia <=1.6

## Installation
`Pkg.add("SimpleWebsockets")`

## Basic usage server:

```julia
using SimpleWebsockets

server = WebsocketServer()
ended = Condition() 

listen(server, :client) do client
    listen(client, :message) do message
        @info "Got a message" client = client.id message = message
        send(client, "Echo back at you: $message")
    end
end
listen(server, :connectError) do err
    notify(ended, err, error = true)
end
listen(server, :closed) do details
    @warn "Server has closed" details...
    notify(ended)
end

@async serve(server; verbose = true)
wait(ended)
```
## Basic usage client:

```julia
using SimpleWebsockets

client = WebsocketClient()
ended = Condition()

listen(client, :connect) do ws
    listen(ws, :message) do message
        @info message
    end
    listen(ws, :close) do reason
        @warn "Websocket connection closed" reason...
        notify(ended)
    end
    for count = 1:10
        send(ws, "hello $count")
        sleep(1)
    end
    close(ws)
end
listen(client, :connectError) do err
    notify(ended, err, error = true)
end

@async open(client, "ws://localhost:8080")
wait(ended)
```
