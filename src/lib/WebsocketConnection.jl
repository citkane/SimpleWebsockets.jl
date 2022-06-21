include("WebsocketFrame.jl")
const ioTypes = Union{Nothing, WebsocketFrame, HTTP.ConnectionPool.Connection, Timer, Closereason, Array{UInt8, 1}}

struct WebsocketConnection
    id::String
    config::NamedTuple
    io::Dict{Symbol, ioTypes}
    callbacks::Dict{Symbol, Union{Bool, Function}}
    buffers::NamedTuple
    closed::Condition
    keepalive::Dict{Symbol, Union{String, Bool}}
    clients::Union{Array{WebsocketConnection,1}, Nothing}
    messageChannel::Channel{Union{String, Array{UInt8,1}}}
    pongChannel::Channel{Union{String, Array{UInt8,1}}}
    validate::Dict{String, Any}

    function WebsocketConnection(
        stream::HTTP.ConnectionPool.Connection,
        config::NamedTuple,
        clients::Union{Array{WebsocketConnection,1}, Nothing} = nothing
    )
        @debug "WebsocketConnection"
        buffers = (
            maskBytes = IOBuffer(; maxsize = 4),
            frameHeader = IOBuffer(; maxsize = 10),
            outBuffer = config.fragmentOutgoingMessages ? IOBuffer(; maxsize = Int(config.fragmentationThreshold) + 10) : IOBuffer(),
            inBuffer = IOBuffer(; maxsize = getmaxwithheaders(config)),
            fragmentBuffer = IOBuffer(; maxsize = Int(config.maxReceivedMessageSize))
        )

        initmessage = "keepalive-"*string(rand(UInt32))
        keepalive = Dict{Symbol, Union{String, Bool}}(
            :pingmessage => initmessage,
            :pongmessage => initmessage,
            :isopen => true,
            :isalive => true,
        )
        interval = config.keepaliveTimeout
        interval !== false && (keepaliveTimer = Timer(timer -> (
            try
                if !keepalive[:isopen]
                    close(timer)
                    return
                end
                if keepalive[:pingmessage] !== keepalive[:pongmessage]
                    self.io[:closeReason] = Closereason(CLOSE_REASON_ABNORMAL, "could not ping the $(config.type === "client" ? "server" : "client").")
                    close(self.io[:stream])
                    gracefulEnd(self)
                    close(timer)
                elseif !keepalive[:isalive]
                    keepalive[:pingmessage] = "keepalive-"*string(rand(UInt32))
                    ping(self, keepalive[:pingmessage])
                end
                keepalive[:isalive] = false
            catch
            end
        ), interval; interval = interval))

        @async begin
            reason = wait(self.closed)
            clients !== nothing && filter!(client -> (client.id !== self.id), clients)
            for buffer in collect(self.buffers)
                close(buffer)
            end
            closecallback = self.callbacks[:close]
            if closecallback isa Function
                closecallback((; code = reason.code, description = reason.description))
            elseif config.type === "client"
                @warn "$(config.type) websocket connection closed." code = reason.code description = reason.description
            end
        end

        atexit(() -> (
            if isopen(self.io[:stream])
                self.io[:closeReason] = Closereason(CLOSE_REASON_ABNORMAL, "julia process exited.")
                close(self.io[:stream])
                wait(self.closed)
                sleep(0.001)
            end
        ))

        self = new(
            requestHash(),
            config,                                                     #config
            Dict{Symbol, ioTypes}(                                      #io
                :stream => stream,
                :currentFrame => WebsocketFrame(config, buffers),
                :closeTimeout => nothing,
                :closeReason => nothing,
                :stash => Array{UInt8, 1}()
            ),
            Dict{Symbol, Union{Bool, Function}}(                        #callbacks
                :message => false,
                :error => false,
                :close => false,
                :pong => false
            ),
            buffers,                                                    #buffers
            Condition(),                                                #closed
            keepalive,                                                  #keepalive
            clients,                                                    #clients
            Channel{Union{String, Array{UInt8,1}}}(Inf),                #messageChannel
            Channel{Union{String, Array{UInt8,1}}}(Inf),                #pongChannel
            Dict{String, Any}("valid" => true)                          #validate
        )
    end
end
"""
    listen(callback::Function, ws::SimpleWebsockets.WebsocketConnection, event::Symbol)
Register event callbacks onto a `WebsocketConnection`. The callback must be a function with exactly one argument.

Valid events are:
- :message
- :pong
- :error
- :close

# Example
```julia
listen(ws::WebsocketConnection, :message) do message
    #...
end
```
"""
function listen(
    cb::Function,
    self::WebsocketConnection,
    key::Symbol   
)
    if !haskey(self.callbacks, key)
        return @warn "WebsocketConnection has no listener for :$key."
    end

    if haskey(self.callbacks, key)
        function errorHandler(err, trace)
            err = CallbackError(err, trace)
            errcallback = self.callbacks[:error]
            if errcallback !== false && key !== :error
                errcallback(err)
            else
                err.log()
                exit()
            end
        end
        if !(self.callbacks[key] isa Function)
            if key === :message
                self.callbacks[key] = data -> ()
                @async while isopen(self.messageChannel)
                    message = take!(self.messageChannel)
                    try
                        cb(message)
                    catch err
                        errorHandler(err, catch_backtrace())
                    end
                end
            elseif key === :pong
                self.callbacks[key] = data -> ()
                @async while isopen(self.pongChannel)
                    message = take!(self.pongChannel)
                    try
                        cb(message)
                    catch err
                        errorHandler(err, catch_backtrace())
                    end
                end            
            else
                self.callbacks[key] = data -> (
                    @async try
                        cb(data)
                    catch err
                        errorHandler(err, catch_backtrace())
                    end
                )
            end
        end
    end
end

function gethandles(connection::WebsocketConnection, io::HTTP.Streams.Stream)
    if connection.config.type === "client"
        (; file = io, available = io,)
    else
        (; file = io.stream, available = io.stream.io)
    end
end
function startConnection(self::WebsocketConnection, io::HTTP.Streams.Stream)
    handle = gethandles(self, io)
    while !eof(handle.file)
        data = readavailable(handle.available)
        isopen(self.io[:stream]) && try
            if length(data) > self.buffers.inBuffer.maxsize
                throw(error("[$CLOSE_REASON_MESSAGE_TOO_BIG]Maximum message size of $(self.config.maxReceivedMessageSize) Bytes exceeded"))
            end
            seekend(self.buffers.inBuffer)
            unsafe_write(self.buffers.inBuffer, pointer(data), length(data))
            processReceivedData(self)
        catch err
            err = FrameError(err, catch_backtrace())
            if self.callbacks[:error] isa Function
                self.callbacks[:error](err)
            elseif self.config.type === "client"
                err.log()
            else
                @debug "CLOSE_REASON_INVALID_DATA" error = err.msg
            end
            closeConnection(self, CLOSE_REASON_INVALID_DATA, err.msg)
        end
    end
    close(self.messageChannel)
    close(self.pongChannel)
    self.keepalive[:isopen] && gracefulEnd(self)
end

function gracefulEnd(self::WebsocketConnection)
    self.keepalive[:isopen] = false
    @async begin
        (   self.io[:closeTimeout] !== nothing &&
            isopen(self.io[:closeTimeout])
        ) && sleep(0.001)

        if self.io[:closeReason] === nothing
            self.io[:closeReason] = Closereason(CLOSE_REASON_ABNORMAL)
        end
        notify(self.closed, self.io[:closeReason]; all = true)
    end
end


function closeConnection(self::WebsocketConnection, reasonCode::Int, reason::String)
    closereason = Closereason(reasonCode, reason)
    self.io[:closeReason] = closereason
    !closereason.valid && throw(error("invalid connection close code."))

    if isopen(self.io[:stream])
        sendCloseFrame(self, closereason.code, closereason.description)

        self.io[:closeTimeout] = Timer(timer -> (
            try
                isopen(self.io[:stream]) && close(self.io[:stream])
            catch
            end
        ), self.config.closeTimeout)

    elseif self.io[:closeTimeout] isa Timer && isopen(self.io[:closeTimeout])
        close(self.io[:closeTimeout])
    end
end

# Send data
"""
    send(ws::WebsocketConnection, data::Union{String, Number, Array{UInt8,1}})
Send the given `data` as a message over the wire.
"""
send(self::WebsocketConnection, data::Number) = send(self, string(data))
send(self::WebsocketConnection, data::String) = send(self, textbuffer(data))
function send(self::WebsocketConnection, data::Array{UInt8,1})
    @debug "WebsocketConnection.send"
    try

        #BUGFIX
        #Julia version < 1.2 gets confused with allocation under fringe circumstances
            VERSION < v"1.2.0" && (data = copy(data))
        #END
        
        frame = WebsocketFrame(self.config, self.buffers, data)
        frame.inf[:opcode] = self.config.binary ? BINARY_FRAME : TEXT_FRAME
        fragmentAndSend(self, frame)
    catch err
        err = FrameError(err, catch_backtrace())
        if self.callbacks[:error] isa Function
            self.callbacks[:error](err)
        else
            err.log()
        end
    end
end


function sendCloseFrame(self::WebsocketConnection, reasonCode::Int, description::String)
    frame = WebsocketFrame(self.config, self.buffers, textbuffer(description));
    frame.inf[:opcode] = CONNECTION_CLOSE_FRAME
    frame.inf[:fin] = true
    frame.inf[:closeStatus] = reasonCode
    sendFrame(self, frame)
end
"""
    ping(ws::WebsocketConnection, data::Union{String, Number})
Send `data` as ping message to the `ws` peer.

`data` is limited to 125Bytes, and will automatically be truncated if over this limit.
"""
ping(self::WebsocketConnection, data::Number) = ping(self, String(data))
function ping(self::WebsocketConnection, data::String)
    try
        data = textbuffer(data)
        size(data, 1) > 125 && (data = data[1:125, 1])
        frame = WebsocketFrame(self.config, self.buffers, data)
        frame.inf[:fin] = true
        frame.inf[:opcode] = PING_FRAME
        sendFrame(self, frame)
    catch err
        err = FrameError(err, catch_backtrace())
        if self.callbacks[:error] isa Function
            self.callbacks[:error](err)
        else
            err.log()
        end
    end
end
pong(self::WebsocketConnection, data::Union{String, Number}) = pong(self, textbuffer(data))
function pong(self::WebsocketConnection, data::Array{UInt8,1})
    size(data, 1) > 125 && (data = data[1:125, 1])
    frame = WebsocketFrame(self.config, self.buffers, data)
    frame.inf[:fin] = true
    frame.inf[:opcode] = PONG_FRAME
    sendFrame(self, frame)
end
function fragmentAndSend(
    self::WebsocketConnection,
    frame::WebsocketFrame,
    numFragments::Int,
    fragment::Int
)
    fragment +=1
    binaryPayload = frame.inf[:binaryPayload]
    endIndex = Int(self.config.fragmentationThreshold)

    if length(binaryPayload) > endIndex
        partialPayload = splice!(binaryPayload, 1:endIndex)
    else
        partialPayload = binaryPayload
    end
    partframe = WebsocketFrame(self.config, self.buffers, partialPayload)
    if fragment === 1
        partframe.inf[:opcode] = frame.inf[:opcode]
    else
        partframe.inf[:opcode] = CONTINUATION_FRAME
    end
    partframe.inf[:fin] = fragment === numFragments
    sendFrame(self, partframe)
    fragment < numFragments && fragmentAndSend(self, frame, numFragments, fragment)
end
function fragmentAndSend(self::WebsocketConnection, frame::WebsocketFrame)
    @debug "WebsocketConnection.fragmentAndSend"
    threshold = self.config.fragmentationThreshold
    len = length(frame.inf[:binaryPayload])
    if !self.config.fragmentOutgoingMessages || len <= threshold
        frame.inf[:fin] = true
        sendFrame(self, frame)
        return
    end
    numFragments = Int(ceil(len / threshold))
    fragmentAndSend(self, frame, numFragments, 0)
end

function sendFrame(self::WebsocketConnection, frame::WebsocketFrame)
    frame.inf[:mask] = self.config.maskOutgoingPackets

    proceed = toBuffer(frame)

    outBuffer = self.buffers.outBuffer
    @debug "WebsocketConnection.sendFrame" (;
        type = self.config.type,
        message = String(copy(frame.inf[:binaryPayload])),
        id = self.id,
        proceed = proceed,
        ptr = outBuffer.ptr,
        buffersize = outBuffer.size,
        parseState = frame.inf[:parseState],
        opcode = frame.inf[:opcode],
        length = Int(frame.inf[:length]),
        fin = frame.inf[:fin],
        mask = frame.inf[:mask],
    )...

    !proceed && return   
    isopen(self.io[:stream]) && write(self.io[:stream], outBuffer)
end
# End send data

# Receive data
function processReceivedData(self::WebsocketConnection)
    frame = self.io[:currentFrame]
    inBuffer = self.buffers.inBuffer

    continued = addData(frame)

    @debug "WebsocketConnection.processReceivedData" (;
        type = self.config.type,
        message = String(copy(frame.inf[:binaryPayload])),
        id = self.id,
        continued = continued,
        ptr = inBuffer.ptr,
        buffersize = inBuffer.size,
        parseState = frame.inf[:parseState],
        opcode = frame.inf[:opcode],
        length = Int(frame.inf[:length]),
        fin = frame.inf[:fin],
        mask = frame.inf[:mask],
    )...

    !continued && return

    processFrame(self, frame)
    self.io[:currentFrame] = WebsocketFrame(
        self.config,
        self.buffers;
            ptr = frame.inf[:ptr]
    )

    if (inBuffer.ptr - 1) < inBuffer.size
        processReceivedData(self)
    else
        self.io[:currentFrame].inf[:ptr] = 1
        isopen(inBuffer) && truncate(inBuffer, 0)
    end
end

function processFrame(self::WebsocketConnection, frame::WebsocketFrame)
    inf = frame.inf
    opcode = inf[:opcode]
    fragmentBuffer = self.buffers.fragmentBuffer
    binary = self.config.binary
    data = inf[:binaryPayload]
    if fragmentBuffer.size > 0 && (opcode > 0x00 && opcode < 0x08)
        throw(error("illegal frame opcode $opcode received in middle of fragmented message."))
    end
    self.keepalive[:isalive] = true
    if opcode === TEXT_FRAME || opcode === BINARY_FRAME
        if length(data) > self.config.maxReceivedMessageSize
            throw(error("[$CLOSE_REASON_MESSAGE_TOO_BIG]Maximum message size of $(self.config.maxReceivedMessageSize) Bytes exceeded"))
        end
        if frame.inf[:fin]
            put!(self.messageChannel, binary ? data : String(data))
        else
            unsafe_write(fragmentBuffer, pointer(data), length(data))
        end
    elseif opcode === CONTINUATION_FRAME

        if fragmentBuffer.size + length(data) > self.config.maxReceivedMessageSize
            throw(error("[$CLOSE_REASON_MESSAGE_TOO_BIG]Maximum message size of $(self.config.maxReceivedMessageSize) Bytes exceeded"))
        end
        unsafe_write(fragmentBuffer, pointer(data), length(data))
        if inf[:fin]
            seekstart(fragmentBuffer)
            data = binary ? read(fragmentBuffer) : read(fragmentBuffer, String)
            isopen(fragmentBuffer) && truncate(fragmentBuffer, 0)
            
            put!(self.messageChannel, binary ? data : String(data))
        end

    elseif opcode === PING_FRAME
        pong(self, inf[:binaryPayload])
    elseif opcode === PONG_FRAME
        callback = self.callbacks[:pong]
        message = String(frame.inf[:binaryPayload])

        if message === self.keepalive[:pingmessage]
            self.keepalive[:pongmessage] = message
        elseif callback isa Function
            put!(self.pongChannel, binary ? textbuffer(message) : message)
        end
    elseif opcode === CONNECTION_CLOSE_FRAME
        description = String(inf[:binaryPayload])
        self.io[:closeReason] = Closereason(inf[:closeStatus], description)
        if !self.io[:closeReason].valid
            @warn "received invalid close reason" code = inf[:closeStatus] description = description
            self.io[:closeReason] = Closereason(CLOSE_REASON_NOT_PROVIDED, description)
        end
        if self.io[:closeTimeout] isa Timer && isopen(self.io[:closeTimeout])
            close(self.io[:closeTimeout])
        end
        isopen(self.io[:stream]) && close(self.io[:stream])
    end
end
# End receive data

"""
    close(ws::WebsocketConnection [, reasonCode::Int, description::String])
Closes a websocket connection.

Sends the close frame to the peer, waits for the response close frame, 
or times out on `closeTimeout` before closing the underlying TCP stream.

Optional `reasonCode` must be a valid [rfc6455](https://tools.ietf.org/html/rfc6455#section-7.4) code, 
suitable for sending over the wire.

Defaults: `1000` : "Normal connection closure"
"""
function Base.close(ws::WebsocketConnection, reasonCode::Int = CLOSE_REASON_NORMAL, description::String = "")
    closeConnection(ws, reasonCode, description)
end
"""
    broadcast(client::WebsocketConnection, data::Union{Array{UInt8,1}, String, Number})
[`send`](@ref) the given `data` as a message to all connected clients, except the given `client`.

In a SERVER context, to communicate with all clients on the SERVER, use [`emit`](@ref)

Only used if the `client` is in a SERVER context, otherwise NOOP.
"""
function Base.broadcast(client::WebsocketConnection, data::Union{Array{UInt8,1}, String, Number})
    client.clients === nothing && return
    for otherclient in client.clients
        otherclient.validate["valid"] !== true && continue
        client.id !== otherclient.id && send(otherclient, data)
    end
end
