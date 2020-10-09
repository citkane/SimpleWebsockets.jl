"""
# The default options for [`WebsocketClient`](@ref)
!!! info "maxReceivedFrameSize"
    `[1 * 0x100000 = 1MiB]::Integer`

    The maximum frame size that the client will accept

!!! info "maxReceivedMessageSize"
    `[8 * 0x100000 = 8MiB]::Integer`

    The maximum assembled message size that the client will accept

!!! info "fragmentOutgoingMessages"
    `[true]::Bool`

    Outgoing frames are fragmented if they exceed the set threshold.

!!! info "fragmentationThreshold"
    `[16 * 0x0400 = 16KiB]::Integer`

    Outgoing frames are fragmented if they exceed this threshold.

!!! info "closeTimeout"
    `[5]::Int`

    The number of seconds to wait after sending a close frame for an acknowledgement to
    return from the server. Will force close the connection if timed out.

!!! info "keepaliveTimeout"
    `[1]::Union{Int, Bool}`

    The interval in number of seconds to solicit the server with a ping / pong
    response. The connection will be closed if no pong is received within the interval.

    The timer is only active when no data is received from the server within the interval,
    ie. the server will only be pinged if inactive for a period longer than the interval.

    `false` to disable.
    !!! warning
        Due to an underlying issue with [HTTP](https://juliaweb.github.io/HTTP.jl/stable/), 
        a client network disconnect will cause the connection to block in it's listen loop, 
        only registering `disconnect` when the network re-connects.

        `keepaliveTimeout` uses ping/pong and will register a disconnect more efficiently
        in network outage events.

!!! info "useNagleAlgorithm"
    `[false]::Bool`

    The Nagle Algorithm makes more efficient use of network resources
    by introducing a small delay before sending small packets so that
    multiple messages can be batched together before going onto the
    wire.  This however comes at the cost of latency, so the default
    is to disable it.  If you don't need low latency and are streaming
    lots of small messages, you can change this to `true`
    !!! info "Julia 1.3"
        This setting only has an affect as of Julia 1.3

!!! info "binary"
    `[false]::Bool`
    
    Use Array{UInt8, 1} instead of String as messaging format.
"""
const clientConfig = (
    maxReceivedFrameSize = 1 * 0x100000,
    maxReceivedMessageSize = 8 * 0x100000,
    fragmentOutgoingMessages = true,
    fragmentationThreshold = 16 * 0x0400,
    closeTimeout = 5,
    keepaliveTimeout = 1,
    useNagleAlgorithm = false,
    binary = false
)
"""
# The default options for [`WebsocketServer`](@ref)
!!! info "ssl"
    `[false]::Bool`

    Whether to use ssl on the server.
    !!! warning
        Due to an underlying [issue](https://github.com/JuliaWeb/HTTP.jl/issues/318) in HTTP, a client calling `ws://` on a `wss:://` 
        server will cause the server to error and close. Ensure that only ssl traffic can
        reach your server port.

!!! info "sslcert"
    `[../src/etc/snakeoil.crt in the SimpleWebsockets module dir]::String`

    Absolute path to your ssl cert

!!! info "sslkey"
    `[../src/etc/snakeoil.key in the SimpleWebsockets module dir]::String`

    Absolute path to your ssl key

!!! info "maxReceivedFrameSize"
    `[64 * 0x0400 = 64KiB]::Integer`

    The maximum frame size that the server will accept

!!! info "maxReceivedMessageSize"
    `[1 * 0x100000 = 1MiB]::Integer`

    The maximum assembled message size that the server will accept

!!! info "fragmentOutgoingMessages"
    `[true]::Bool`

    Outgoing frames are fragmented if they exceed the set threshold.

!!! info "fragmentationThreshold"
    `[16 * 0x0400 = 16KiB]::Integer`

    Outgoing frames are fragmented if they exceed this threshold.

!!! info "closeTimeout"
    `[5]::Int`

    The number of seconds to wait after sending a close frame for an acknowledgement to
    return from the client. Will force close the client if timed out.

!!! info "keepaliveTimeout"
    `[20]::Union{Int, Bool}`

    The interval in number of seconds to solicit each client with a ping / pong
    response. The client will be closed if no pong is received within the interval.

    The timer is only active when no data is received from the client within the interval,
    ie. the client will only be pinged if inactive for a period longer than the interval.

    `false` to disable.
    !!! warning
        Due to an underlying issue with [HTTP](https://juliaweb.github.io/HTTP.jl/stable/), 
        a server network disconnect will cause all clients to block in their listen loop, 
        only registering `disconnect` when the network re-connects.

        `keepaliveTimeout` uses ping/pong and will register the client disconnects more efficiently
        in network outage events.

!!! info "useNagleAlgorithm"
    `[false]::Bool`

    The Nagle Algorithm makes more efficient use of network resources
    by introducing a small delay before sending small packets so that
    multiple messages can be batched together before going onto the
    wire.  This however comes at the cost of latency, so the default
    is to disable it.  If you don't need low latency and are streaming
    lots of small messages, you can change this to `true`

    !!! info "Julia 1.3"
        This setting only has an affect as of Julia 1.3

!!! info "binary"
    `[false]::Bool`
    
    Use Array{UInt8, 1} instead of String as messaging format.
"""
const serverConfig = (
    ssl = false,
    sslcert = joinpath(dirname(pathof(SimpleWebsockets)), "etc/snakeoil.crt"),
    sslkey = joinpath(dirname(pathof(SimpleWebsockets)), "etc/snakeoil.key"),
    maxReceivedFrameSize = 64 * 0x0400,
    maxReceivedMessageSize = 1 * 0x100000,
    fragmentOutgoingMessages = true,
    fragmentationThreshold = 16 * 0x0400,
    closeTimeout = 5,
    keepaliveTimeout = 20,
    useNagleAlgorithm = false,
    binary = false
)
"""
    defaultHeaders::Dict{String, String}
The default headers passed to a http upgrade request
```julia
Dict{String, String}(
    "Sec-WebSocket-Version" => "13",
    "Upgrade" => "websocket",
    "Connection" => "Upgrade",
    "Sec-WebSocket-Key" => "", #new key made for every request
)
```
"""
const defaultHeaders = Dict{String, String}(
    "Sec-WebSocket-Version" => "13",
    "Upgrade" => "websocket",
    "Connection" => "Upgrade",
    "Sec-WebSocket-Key" => "",
)
const clientOptions = (;
    reuse_limit = 0,
)
const serverOptions = (;
    sslconfig = nothing,
    verbose = false
)

const CONTINUATION_FRAME = 0x00
const TEXT_FRAME = 0x01
const BINARY_FRAME = 0x02
const CONNECTION_CLOSE_FRAME = 0x08
const PING_FRAME = 0x09
const PONG_FRAME = 0x0a

const WS_FINAL = 0x80
const WS_OPCODE = 0x0F
const WS_MASK = 0x80
const WS_LENGTH = 0x7F
const WS_RSV1 = 0x40
const WS_RSV2 = 0x20
const WS_RSV3 = 0x10

const DECODE_HEADER = 1
const WAITING_FOR_16_BIT_LENGTH = 2
const WAITING_FOR_64_BIT_LENGTH = 3
const WAITING_FOR_MASK_KEY = 4
const WAITING_FOR_PAYLOAD = 5
const COMPLETE = 6

const CLOSE_REASON_NORMAL = 1000
const CLOSE_REASON_GOING_AWAY = 1001
const CLOSE_REASON_PROTOCOL_ERROR = 1002
const CLOSE_REASON_UNPROCESSABLE_INPUT = 1003
const CLOSE_REASON_RESERVED = 1004              #Not to be used on the wire. Reserved value.  Undefined meaning.
const CLOSE_REASON_NOT_PROVIDED = 1005          #Not to be used on the wire
const CLOSE_REASON_ABNORMAL = 1006              #Not to be used on the wire
const CLOSE_REASON_INVALID_DATA = 1007
const CLOSE_REASON_POLICY_VIOLATION = 1008
const CLOSE_REASON_MESSAGE_TOO_BIG = 1009
const CLOSE_REASON_EXTENSION_REQUIRED = 1010
const CLOSE_REASON_INTERNAL_SERVER_ERROR = 1011
const CLOSE_REASON_TLS_HANDSHAKE_FAILED = 1015
const CLOSE_DESCRIPTIONS = Dict{Int, String}(
    1000 => "Normal connection closure",
    1001 => "Remote peer is going away",
    1002 => "Protocol error",
    1003 => "Unprocessable input",
    1004 => "Reserved",
    1005 => "Reason not provided",
    1006 => "Abnormal closure, no further detail available",
    1007 => "Invalid data received",
    1008 => "Policy violation",
    1009 => "Message too big",
    1010 => "Extension requested by client is required",
    1011 => "Internal Server Error",
    1015 => "TLS Handshake Failed"
)
