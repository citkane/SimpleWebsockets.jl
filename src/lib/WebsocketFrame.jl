struct WebsocketFrame
    config::NamedTuple
    buffers::NamedTuple
    inf::Dict{Symbol, Any}
    function WebsocketFrame(
        config::NamedTuple,
        buffers::NamedTuple,
        binaryPayload::Array{UInt8, 1} = Array{UInt8, 1}();
            ptr::Int = 1,
    )
        inf = Dict{Symbol, Any}(
            :fin => false,
            :mask => false,
            :opcode => 0x00,
            :rsv1 => 0x00,
            :rsv2 => 0x00,
            :rsv3 => 0x00,
            :length => 0x00,
            :parseState => DECODE_HEADER,
            :binaryPayload => binaryPayload,
            :ptr => ptr,
        )
        self = new(
            config,
            buffers,
            inf,
        )
    end
end

function toBuffer(self::WebsocketFrame)

    outBuffer = self.buffers.outBuffer
    !isopen(outBuffer) && return false
    truncate(outBuffer, 0)
    maskBytes = self.buffers.maskBytes
    inf = self.inf
    firstByte = 0x00
    secondByte = 0x00
    inf[:fin] && (firstByte |= 0x80)
    inf[:mask] && (secondByte |= 0x80)
    firstByte |= (inf[:opcode] & 0x0F)

    if inf[:opcode] === CONNECTION_CLOSE_FRAME
        closeStatus = reinterpret(UInt8, [hton(UInt16(inf[:closeStatus]))])
        pushfirst!(inf[:binaryPayload], closeStatus...)
    end

    len = length(inf[:binaryPayload])

    if len <= 125
        secondByte |= (len & 0x7F)
    elseif len > 125 && len <= 0xFFFF
        secondByte |= 126
    elseif len > 0xFFFF
        secondByte |= 127
    end

    write(outBuffer, UInt8(firstByte), UInt8(secondByte))

    if len > 125 && len <= 0xFFFF
        write(outBuffer, hton(UInt16(len)))
    elseif len > 0xFFFF
        write(outBuffer, hton(0x00000000), hton(UInt32(len)))
    end

    if inf[:mask]
        seekstart(maskBytes)
        write(maskBytes, hton(rand(UInt32)))
        seekstart(maskBytes)
        write(outBuffer, maskBytes)
        mask!(maskBytes, inf[:binaryPayload])
    end

    unsafe_write(outBuffer, pointer(inf[:binaryPayload]), len)
    seek(outBuffer, 0)
    return true
end

function addData(self::WebsocketFrame)

    inf = self.inf
    header = self.buffers.frameHeader
    inBuffer = self.buffers.inBuffer
    maskBytes = self.buffers.maskBytes
    seek(inBuffer, inf[:ptr] - 1)

    if inf[:parseState] === DECODE_HEADER && inBuffer.size >= 2
        seekstart(header)
        write(header, read(inBuffer, 2))
        inf[:ptr] = inBuffer.ptr
        firstByte = header.data[1]
        secondByte = header.data[2]
        inf[:fin] = firstByte & WS_FINAL > 0
        inf[:mask] = secondByte & WS_MASK > 0
        inf[:opcode] = firstByte & WS_OPCODE
        inf[:length] = secondByte & WS_LENGTH
        inf[:rsv1] = firstByte & WS_RSV1 > 0
        inf[:rsv2] = firstByte & WS_RSV2 > 0
        inf[:rsv3] = firstByte & WS_RSV3 > 0

        if inf[:rsv1] || inf[:rsv2] || inf[:rsv2]
            throw(error("[$CLOSE_REASON_POLICY_VIOLATION]websocket extensions are not supported"))
        end

        if inf[:opcode] >= 0x08
            inf[:length] > 125 && throw(error("illegal control frame longer than 125 bytes."))
            !inf[:fin] && throw(error("control frames must not be fragmented."))
        end

        if inf[:length] === 0x7e
            inf[:parseState] = WAITING_FOR_16_BIT_LENGTH
        elseif inf[:length] === 0x7f
            inf[:parseState] = WAITING_FOR_64_BIT_LENGTH
        else
            inf[:parseState] = WAITING_FOR_MASK_KEY
        end

    end
    if inf[:parseState] === WAITING_FOR_16_BIT_LENGTH
        if inBuffer.size >= 2
            write(header, read(inBuffer, 2))
            inf[:ptr] = inBuffer.ptr
            ptr = header.ptr
            seek(header, 2)
            inf[:length] = Int(ntoh(read(header, UInt16)))
            seek(header, ptr - 1)
            inf[:parseState] = WAITING_FOR_MASK_KEY
        end
    elseif inf[:parseState] === WAITING_FOR_64_BIT_LENGTH
        if inBuffer.size >= 8
            write(header, read(inBuffer, 8))
            inf[:ptr] = inBuffer.ptr
            ptr = header.ptr
            seek(header, 2)
            lengthPair = [
                Int(ntoh(read(header, UInt32))),
                Int(ntoh(read(header, UInt32)))
            ]
            if lengthPair[1] !== 0
                throw(error("Unsupported 64-bit length frame received"))
            end
            inf[:length] = lengthPair[2]
            inf[:parseState] = WAITING_FOR_MASK_KEY
        end
    end
    if inf[:parseState] === WAITING_FOR_MASK_KEY
        if inf[:mask]
            if inBuffer.size >= 4
                seekstart(maskBytes)
                write(maskBytes, read(inBuffer, 4))
                inf[:ptr] = inBuffer.ptr
                inf[:parseState] = WAITING_FOR_PAYLOAD
            end
        else
            inf[:parseState] = WAITING_FOR_PAYLOAD
        end
    end
    if inf[:parseState] === WAITING_FOR_PAYLOAD

        if inf[:length] > self.config.maxReceivedFrameSize
            throw(error("[$CLOSE_REASON_POLICY_VIOLATION]frame size exceeds maximum of $(self.config.maxReceivedFrameSize) Bytes."))
        end
        if inBuffer.size - (inf[:ptr] - 1) >= inf[:length]
            inf[:binaryPayload] = read(inBuffer, inf[:length])
            inf[:ptr] = inBuffer.ptr
            inf[:mask] && mask!(maskBytes, inf[:binaryPayload])

            if inf[:opcode] === CONNECTION_CLOSE_FRAME
                inf[:length] < 2 && throw(error("close frame too small"))
                status = IOBuffer(splice!(inf[:binaryPayload], 1:2))
                inf[:closeStatus] = Int(ntoh(read(status, UInt16)))
                close(status)
            end

            inf[:parseState] = COMPLETE

            return true
        end
    end
    return false
end
