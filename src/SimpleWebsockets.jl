__precompile__()
module SimpleWebsockets
using HTTP, Sockets, Base64, MbedTLS

export  WebsocketServer,
        WebsocketClient,
        WebsocketConnection,
        RequestDetails,
        WebsocketError,
        ConnectError,
        CallbackError,
        FrameError
        
export serve, send, ping, listen, emit

include("opt/errors.jl")
include("opt/vars.jl")
include("opt/utils.jl")
include("lib/WebsocketConnection.jl")
include("lib/WebsocketClient.jl")
include("lib/WebsocketServer.jl")

end
