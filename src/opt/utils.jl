struct Closereason
    code::Int
    description::String
    valid::Bool
    function Closereason(code::Int, description::String = "")
        if length(description) === 0 && haskey(CLOSE_DESCRIPTIONS, code)
            description = CLOSE_DESCRIPTIONS[code]
        end

        parsed = parsedescription(description)
        parsed[2] !== nothing && (code = parsed[2])
        description = parsed[1]
        new(
            code,
            description,
            validateCloseReason(code),
        )
    end
end

function parsedescription(description::String)::Array{Union{String, Int, Nothing}, 1}
    reg = r"^\[(\d+)*?\]"
    code = nothing
    description = replace(description, reg => newcode -> (
        begin
            result = match(reg, newcode).captures[1]
            result !== nothing && (code = parse(Int, result))
            s""
        end
    ))
    [description, code]
end
function validateCloseReason(code::Int)
    if code < 1000
        #Status codes in the range 0-999 are not used
        return false;
    end
    if code >= 1000 && code <= 2999
        #Codes from 1000 - 2999 are reserved for use by the protocol.  Only
        #a few codes are defined, all others are currently illegal.
        return code in [1000, 1001, 1002, 1003, 1007, 1008, 1009, 1010, 1011, 1012, 1013, 1014, 1015]
    end
    if code >= 3000 && code <= 3999
        #Reserved for use by libraries, frameworks, and applications.
        #Should be registered with IANA.  Interpretation of these codes is
        #undefined by the WebSocket protocol.
        return true;
    end
    if code >= 4000 && code <= 4999
        #Reserved for private use.  Interpretation of these codes is
        #undefined by the WebSocket protocol.
        return true;
    end
    if code >= 5000
        return false;
    end
end

requestHash() = base64encode(rand(UInt8, 16))
function acceptHash(key::String)
    hashkey = "$(key)258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    base64encode(digest(MD_SHA1, hashkey))
end

textbuffer(data::String)::Array{UInt8,1} = Array{UInt8,1}(data)
textbuffer(data::Number)::Array{UInt8,1} = Array{UInt8,1}(string(data))

modindex(i::Int, m::Int) = ((i-1) % m) + 1
function mask!(mask::IOBuffer, data::Array{UInt8, 1})
    for (i, value) in enumerate(data)
       data[i] = value ⊻ mask.data[modindex(i, mask.size)]
    end
end

function makeHeaders(extend::Dict{String, String})
    headers = Dict{String, String}(
        "Sec-WebSocket-Version" => defaultHeaders["Sec-WebSocket-Version"],
    )
    for (key, value) in extend
        headers[key] = value
    end
    headers["Upgrade"] = defaultHeaders["Upgrade"]
    headers["Connection"] = defaultHeaders["Connection"]
    headers["Sec-WebSocket-Key"] = requestHash()

    headers
end

function getmaxwithheaders(config::NamedTuple)
    !config.fragmentOutgoingMessages && return (Int(config.maxReceivedMessageSize) + 10)
    Int(config.maxReceivedMessageSize + (ceil(config.maxReceivedMessageSize / config.fragmentationThreshold)*10))
end

function explain(object::Any)
    type = typeof(object)
    @show type
    println("----------------------------------")
    for field in fieldnames(type)
        value = getfield(object, field)
        println(field, " | ", typeof(value), " | ", value)
    end
    println("----------------------------------")
end
"""
    (headers, queries, basicauth)

Provides:
- `headers::NamedTuple` All request headers 
- `queries::NamedTuple` All request query parameters
- `basicauth::Function` returns NamedTuple(username, password) if found, or `nothing`

`basicauth` will first look for basicauth details in the headers, then the parameters, returning the first one found or `nothing`

Optionally, `basicauth` can be passed two parameters:

`basicauth([usernamekey::String, passwordkey::String])`

which define which query parameters to look up. Defaults to `("username","password")`.

# Example:
```julia
function authfunction(details::RequestDetails)
    headers = details.headers
    queries = details.queries
    auth = details.basicauth()

    auth !== nothing && return auth.username === username && auth.password === password
    return false 
end
```
"""
struct RequestDetails
    headers::NamedTuple
    queries::NamedTuple
    basicauth::Function
    function RequestDetails(headers::NamedTuple, queries::NamedTuple)
        self = new(
            headers,
            queries,
            (usernamekey::String = "username", passwordkey::String = "password") -> getbasicauth(self.headers, self.queries, usernamekey, passwordkey)
        )
    end
end
function getbasicauth(headers::NamedTuple, queries::NamedTuple, usernamekey::String, passwordkey::String)
    try
        auth = headers.Authorization
        !startswith(auth, "Basic") && throw(error("not basic auth"))
        encoded = split(auth, " ")[2]
        length(encoded) === 0 && throw(error("nothing given"))
        encoded = split(String(base64decode(encoded)), ":")
        return (;
            username = string(encoded[1]),
            password = string(encoded[2]),
        )
    catch
    end
    try
        return (;
            username = queries[Symbol(usernamekey)],
            password = queries[Symbol(passwordkey)],        
        )
    catch
    end
    return nothing
end
