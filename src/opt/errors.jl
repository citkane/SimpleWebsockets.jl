"""
    abstract type WebsocketError <: Exception
WebsocketError child error types have the following fields:
- msg::String
- log::Function

The `log()` function will internally call: @error msg  exception = (err, trace)

Where `trace` is the backtrace of the exception origin.
"""
abstract type WebsocketError <: Exception end
function msg(err::Exception)
    try
        return err.msg
    catch
        return string(typeof(err))
    end
    # hasfield(typeof(err), :msg) ? err.msg : string(typeof(err)) #hasfield needs julia >= 1.2
end
logError(self::Exception, err::Exception, trace::Array) = @error string(typeof(self))*"(\"$(self.msg)\")" exception = (err, trace)

"""
    struct ConnectError <: WebsocketError 
An exception originated while trying to start a server or connect a client to a server
"""
struct ConnectError <: WebsocketError
    msg::String
    log::Function
    function ConnectError(err::Exception, trace::Array{Union{Ptr{Nothing}, Base.InterpreterIP},1} = [])
        self = new(
            msg(err),
            () -> logError(self, err, trace)
        )
    end
end
"""
    struct PeerConnectError <: WebsocketError 
The server made an exception when a client tried to connect
"""
struct PeerConnectError <: WebsocketError
    msg::String
    log::Function
    function PeerConnectError(err::Exception, trace::Array{Union{Ptr{Nothing}, Base.InterpreterIP},1} = [])
        self = new(
            msg(err),
            () -> logError(self, err, trace)
        )
    end
end
"""
    struct CallbackError <: WebsocketError
An exception originated in a user provided callback function
"""
struct CallbackError <: WebsocketError
    msg::String
    log::Function
    function CallbackError(err::Exception, trace::Array{Union{Ptr{Nothing}, Base.InterpreterIP},1} = [])
        self = new(
            msg(err),
            () -> logError(self, err, trace)
        )
    end
end
"""
    struct FrameError <: WebsocketError
An exception originated while parsing a websocket data frame
"""
struct FrameError <: WebsocketError
    msg::String
    log::Function
    function FrameError(err::Exception, trace::Array{Union{Ptr{Nothing}, Base.InterpreterIP},1} = [])
        self = new(
            msg(err),
            () -> logError(self, err, trace)
        )
    end
end

function Base.showerror(io::IO, e::WebsocketError)
    print(io, "$(typeof(e)): ")
    print(io, e.msg)
end