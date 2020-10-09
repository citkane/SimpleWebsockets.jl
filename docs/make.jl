push!(LOAD_PATH,"../src/")

using Documenter, SimpleWebsockets

makedocs(
    sitename = "SimpleWebsockets",
    format = Documenter.HTML(),
    modules = [SimpleWebsockets],
    pages = [
        "Introduction" => "index.md",
        "Server" => [
            "Server Usage" => "WebsocketServer.md",
            "Server Options" => "ServerOptions.md",
        ],
        "Client" => [
            "Client Usage" => "WebsocketClient.md",
            "Client Options" => "ClientOptions.md",
        ],
        "Websocket Connection" => "WebsocketConnection.md",
        "Error handling" => "Errors.md",
        "Acknowledgments" => "Acknowledgments.md"
    ]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/citkane/SimpleWebsockets.jl.git"
)
