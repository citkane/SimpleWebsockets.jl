# Error Handling

Websockets are inherently asynchronous, so error handling can be inflexible.

SimpleWebsockets.jl offers the user event hooks to register callbacks and handle errors flexibly.

SEE: [Server Events](@ref), [Client Events](@ref), [Connection Events](@ref WebsocketConnection-Events)

If no callbacks are registered, hardcoded `@info`, `@warn` and `@error` calls will provide logging feedback, but the parent process will remain unaffected by exceptions unless as below.

Errors in user provided callback error handlers will log the error and `exit` the process.

Unregistered callbacks for the following situations will log the error and `exit` the process:

- A error occured in a user provided callback function
- The client/server could not initialise on the network

```@meta
CurrentModule = SimpleWebsockets
```
## WebsocketError
```@docs
WebsocketError
```
## WebsocketError types
```@docs
ConnectError
PeerConnectError
CallbackError
FrameError
```