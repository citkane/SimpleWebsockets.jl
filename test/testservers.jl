function servercanlisten(server::WebsocketServer, port::Int = 8080)
    ended = Condition()
    
    listen(server, :connectError) do  err
        notify(ended, err.msg)
    end
    listen(server, :listening) do detail
        close(server)
    end
    listen(server, :client) do client
    end
    listen(server, :closed) do detail
        notify(ended, detail)
    end

    @async serve(server, port)

    wait(ended)
end

function echoserver(server::WebsocketServer, port::Int = 8080)
    started = Condition()

    listen(server, :client) do ws
        listen(ws, :message) do message
            send(ws, message)
        end
    end
    listen(server, :listening) do detail
        notify(started, server)
    end

    @async serve(server, port)

    wait(started)
end
