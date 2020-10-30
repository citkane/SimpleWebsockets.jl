using Base64, MbedTLS

include("../src/opt/vars.jl")
include("../src/opt/utils.jl")

@debug "Closereason"
reason = Closereason(CLOSE_REASON_NORMAL)
@test reason.code === CLOSE_REASON_NORMAL
@test reason.description === CLOSE_DESCRIPTIONS[CLOSE_REASON_NORMAL]
@test reason.valid
for code in [CLOSE_REASON_RESERVED, CLOSE_REASON_NOT_PROVIDED, CLOSE_REASON_ABNORMAL]
    local reason = Closereason(code)
    @test reason.code === code
    @test reason.description === CLOSE_DESCRIPTIONS[code]
    @test !reason.valid
end
reason = Closereason(0, "[1000]parsed description")
@test reason.code === 1000
@test reason.description === "parsed description"
@test reason.valid

@debug "WebsocketError"
for errtype in [SimpleWebsockets.ConnectError, SimpleWebsockets.CallbackError, SimpleWebsockets.FrameError]
    try
        1 ÷ 0
    catch err
        @suppress_err begin
            err = errtype(err, catch_backtrace())
            @test err isa errtype
            @test err.msg === "DivideError"
            @test_nowarn err.log()
        end
    end
end

@debug "requestHash"
h1 = requestHash()
h2 = requestHash()
@test length(h1) === 24
@test length(h1) === length(h2)
@test h1 !== h2

@debug "acceptHash"
ahash = @test_nowarn acceptHash(h1)
@test ahash isa String
@test length(ahash) === 28

@debug "textbuffer"
bin1 = textbuffer(123456789)
bin2 = textbuffer("123456789")
@test isequal(bin1, bin2)
@test length(bin1) === 9
@test bin1 isa Array{UInt8,1}

@debug "mask!"
maskBytes = IOBuffer(; maxsize = 4)
write(maskBytes, hton(rand(UInt32)))

@test_nowarn mask!(maskBytes, bin1)
@test bin1 isa Array{UInt8,1}
@test !isequal(bin1, bin2)
mask!(maskBytes, bin1)
@test isequal(bin1, bin2)

@debug "makeHeaders"
headers = @test_nowarn makeHeaders(Dict(
    "foo" => "bar",
    "Sec-WebSocket-Version" => "8",
    "Upgrade" => "foobar"
))
for key in ["Connection", "Sec-WebSocket-Version", "Upgrade", "foo", "Sec-WebSocket-Key"]
    @test haskey(headers, key)
end
@test headers["Connection"] === "Upgrade"
@test headers["Sec-WebSocket-Version"] === "8"
@test headers["Upgrade"] === "websocket"
@test headers["foo"] === "bar"
@test length(headers["Sec-WebSocket-Key"]) === 24

@debug "getmaxwithheaders"
max = @test_nowarn getmaxwithheaders(serverConfig)
@test max isa Int
@test max > serverConfig.maxReceivedMessageSize

@debug "explain"
@suppress begin
    @test_nowarn explain(Dict())
end
