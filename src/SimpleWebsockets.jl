__precompile__()
module SimpleWebsockets
using HTTP, Base64, Sockets, MbedTLS
import Sockets: listen

export WebsocketServer, WebsocketClient, WebsocketConnection, WebsocketError, serve, send, ping, listen, emit, throwWSerror, logWSerror

include("opt/vars.jl")
include("opt/utils.jl")
include("lib/WebsocketConnection.jl")
include("lib/WebsocketClient.jl")
include("lib/WebsocketServer.jl")

"""
    logWSerror(err::Union{Exception, WebsocketError})
A convenience method to lift errors into a scope and log them.
# Example
```julia
using SimpleWebsockets

server = WebsocketServer()
ended = Condition()

listen(server, :client) do client end
listen(server, :connectError) do err::WebsocketError
    notify(ended, err)
end

@async serve(server, 8080, "notahost")

reason = wait(ended)
reason isa Exception && logWSerror(reason)
```
"""
function logWSerror(err::WebsocketError)
    err.log()
end
function logWSerror(err::Exception)
    @error err
end
"""
    throwWSerror(err::Union{Exception, WebsocketError})
A convenience method to lift fatal errors into a scope and throw them.
# Example
```julia
using SimpleWebsockets

server = WebsocketServer()
ended = Condition()

listen(server, :client) do client end
listen(server, :connectError) do err::WebsocketError
    notify(ended, err)
end

@async serve(server, 8080, "notahost")

reason = wait(ended)
reason isa Exception && throwWSerror(reason)
```
"""
function throwWSerror(err::WebsocketError)
    err.log()
    throw(err)
end
function throwWSerror(err::Exception)
    throw(err)
end
end
