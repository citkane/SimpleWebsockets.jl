using SimpleWebsockets
using Test, Suppressor
import Sockets: getaddrinfo
include("testservers.jl")
include("testclients.jl")

@testset "SimpleWebsockets" begin
    @info "Testing SimpleWebsockets"
    @test_nowarn WebsocketServer()
    @test_nowarn WebsocketClient()

    server1 = WebsocketServer()
    client = WebsocketClient()
    @suppress begin
        @test_nowarn listen(server1, :invalidlistener) do noop end
        @test_nowarn listen(client, :invalidlistener) do noop end
    end

    @testset "Unit Tests" begin
        @info "Unit Tests"
        include("unittests.jl")
    end

    @testset "Server listens and closes" begin
        @info "Server listens and closes"
        for config in [(; ssl = false), (; ssl = true)]
            server2 = WebsocketServer(; config...)
            details = @test_nowarn servercanlisten(server2, 8080)
            @test details isa NamedTuple
            @test haskey(details, :port)
            @test haskey(details, :host)
            @test details.port === 8080
            @test details.host === getaddrinfo("localhost")
            @test !isopen(server2)
        end
    end

    @testset "Client connects and disconnects on ws and wss" begin
        @info "Client connects and disconnects on ws and wss"
        for config in [
            (; server = (; ssl = false,), client = (; url = "ws://localhost",)),
            (; server = (; ssl = true,), client = (; url = "wss://localhost",))
        ]
            server3 = WebsocketServer(; config.server...)
            @test_nowarn echoserver(server3, 8080)
            client = WebsocketClient()
            @suppress begin
                closed = @test_nowarn clientconnects(client, 8080, config.client.url)
                @test !isopen(client)
                @test closed isa NamedTuple
                @test haskey(closed, :code)
                @test haskey(closed, :description)
                @test closed.code === 1000
                @test closed.description === "Normal connection closure"
                @test length(server3) === 0
                @test_nowarn close(server3)
            end
        end
    end
    @testset "Client passes connection errors to callback handler" begin
        @info "Client passes connection errors to callback handler" wait = "wait for socket to timeout..."
        client = WebsocketClient()
        err = clientconnects(client, 8080, "ws://badurl.bad")
        @test err isa ConnectError
        @test err.msg === "Sockets.DNSError"
    end
    @testset "Client sends and receives messages up to max payload" begin
        @info "Client sends and receives messages up to max payload" (;
            description = "This incrementally scales data payload to the echo server up to the maximum allowed",
            purpose = "Scale through [8, 16, 32]bit payloads and fragmentation in text / binary combo's",
            time = "Please wait, moving a lot of test data..."
        )...
        for binary in [true, false]
            @info "Testing $(binary ? "binary" : "text") server."
            local server4 = WebsocketServer(; binary = binary)
            echoserver(server4, 8080)
            count = 0
            @sync for clientbinary in [true, false]
                count += 1
                @info "Opening $(clientbinary ? "binary" : "text") client $count"
                local client = WebsocketClient(; binary = clientbinary)
                @async begin
                    closed = echoclient(client, 8080; server4.config...)
                    @test !isopen(client)
                    @test closed.code === 1000
                    @test closed.description === "Normal connection closure"
                end
            end
            close(server4)
        end
        @info "...Done"
    end

    @testset "Server client feedback" begin
        server5 = WebsocketServer()
        echoserver(server5, 8080)

        @testset "ping pong" begin
            @info "ping pong"
            client = WebsocketClient()
            closed = pingclient(client, 8080)
            @test closed === "testping"
            @test !isopen(client)
            @test isopen(server5)
        end
        
        @testset "Server rejects clients with bad payloads" begin
            @info "Server rejects clients with bad payloads"           
            client = WebsocketClient()
            closed = badclient(client, 8080)
            @test closed.code === 1009
            @test closed.description === "Maximum message size of 1048576 Bytes exceeded"
            @test !isopen(client)
            @test isopen(server5)
            client = WebsocketClient(; fragmentOutgoingMessages = false)
            closed = badclient(client, 8080)
            @test closed.code === 1008
            @test closed.description === "frame size exceeds maximum of 65536 Bytes."
            @test !isopen(client)
            @test isopen(server5)
        end

        @testset "Client times out" begin
            @info "Client times out"
            client = WebsocketClient()
            closed = timeoutclient(client, 8080)
            @test closed.code === 1006
            @test closed.description === "could not ping the server."
            @test !isopen(client)
            @test isopen(server5)
            close(server5)
        end

        server6 = WebsocketServer()
        echoserver(server6, 8080)

        @testset "server gracefully closes clients and exits" begin
            @info "server gracefully closes clients and exits"         
            client = WebsocketClient()
            client2 = WebsocketClient()
            local reason, reason2
            @async reason = wsclient(client)
            @async reason2 = wsclient(client2)
            while length(server6) < 2
                sleep(0.1)
            end
            @test length(server6) === 2
            close(server6)

            @test !isopen(client)
            @test !isopen(client2)
            @test !isopen(server6)
            for r in [reason, reason2]
                @test r.code === 1001
                @test r.description === "Remote peer is going away"
            end
        end
    end
end
