##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## websocket middleware
## handle websocket upgrade
## from http
##


import
  ../../macros/sugar,
  ../../core/routes,
  ../../core/environment


@!App:
  @!Before:
    # if header key containts upgrade websocket then the request is websocket
    # websocket only accept get method
    if @!WebSocket.isNil:
      let upgradeProtocol =  @!Req.headers.getValues("upgrade")
      if "websocket" in upgradeProtocol and @!Req.httpMethod == HttpGet:

        if @!Req.uri.getScheme() == "http":
          @!Req.uri.setScheme("ws")

        else:
          @!Req.uri.setScheme("wss")

        @!WebSocket = newWebSocket(
            client = @!Client,
            state = WsState.HandShake
          )

        @!WebSocket.uri = @!Req.uri
        @!WebSocket.client = @!Client
        @!WebSocket.handShakeReqHeaders = @!Req.headers

    # if websocket still nil then return
    # don't evaluate rest of websocket handler
    if @!WebSocket.isNil: return

    # check if state is handshake and
    # status code ok
    # if handshake success the change state to open
    if @!WebSocket.state == WsState.HandShake and
      @!WebSocket.statusCode == WsStatusCode.Ok:
      @!WebSocket.state = WsState.Open

    case @!WebSocket.state
    of WsState.Open:
      # if web socket
      # then handle the message and the connection
      # the fin = 1 indicate that the message from the client already sent
      # but if fin = 0 indicate that the message has another part until fin = 1
      #
      # get the first 2 byte and define
      # fin flag (1 bit)
      # rsv 1 - rsv 3 (1 bit each)
      # opcode (4 bit)
      # mask flag (1 bit), 1 meaning message is masked
      # payload length (7 bit)


      # set default status code to Ok
      @!WebSocket.statusCode = WsStatusCode.Ok
      # create websocket frame
      # set websocket input frame
      @!WebSocket.inFrame = WSFrame()

      # get header first 2 bytes
      let header = await @!WebSocket.client.recv(2)
      # make sure header containt 2 bytes (string with len 2)
      if header.len == 2 and header.strip() != "":
        # parse the headers frame
        @!WebSocket.inFrame.parseHeaders(header)

        # if payload len 126 (0x7e)
        # get the length of the data from the
        # next 2 bytes
        # get extended payload length next 2 bytes
        if @!WebSocket.inFrame.payloadLen == 0x7e:
          @!WebSocket.inFrame.parsePayloadLen(await @!WebSocket.client.recv(2))
        # if payload len 127 (0x7f)
        # get the length of the data from the
        # next 8 bytes
        # get extended payload length next 8 bytes
        elif @!WebSocket.inFrame.payloadLen == 0x7f:
          @!WebSocket.inFrame.parsePayloadLen(await @!WebSocket.client.recv(8))

        # check if the payload len is not larget than allowed max
        # max is maxRecvSize
        # if payloadLen larget than max int then
        # send error and
        if @!WebSocket.inFrame.payloadLen <= @!Settings.maxRecvSize.uint64:
          # if isMasked then get the mask key
          # next 4 bytes (uint32)
          if @!WebSocket.inFrame.mask != 0x0:
            @!WebSocket.inFrame.maskKey = await @!WebSocket.client.recv(4)

          # get payload data
          # asyncnet.recv(int32) only accept int32
          # payloadLen is uint64, we need to retrieve in part of int32
          if @!WebSocket.inFrame.payloadLen != 0:
            @!WebSocket.inFrame.payloadData = ""
            var retrieveCount = (@!WebSocket.inFrame.payloadLen div high(int32).uint64).uint64

            if retrieveCount == 0:
              @!WebSocket.inFrame.payloadData = await @!WebSocket.client.recv(@!WebSocket.inFrame.payloadLen.int32)

            else:
              let restToRetrieve = @!WebSocket.inFrame.payloadLen mod high(int32).uint64
              for i in 0..retrieveCount:
                @!WebSocket.inFrame.payloadData &= await @!WebSocket.client.recv(high(int32))

              if restToRetrieve != 0:
                @!WebSocket.inFrame.payloadData &= await @!WebSocket.client.recv(restToRetrieve.int32)

        else:
          @!WebSocket.state = WsState.Close
          @!WebSocket.statusCode = WsStatusCode.PayloadToBig
          @!WebSocket.client.close

      else:
        @!WebSocket.state = WsState.Close
        @!WebSocket.statusCode = WsStatusCode.BadPayload
        @!WebSocket.client.close


      case @!WebSocket.inFrame.opCode
      # response the ping with same message buat change the opcode to pong
      of WsOpCode.Ping.uint8:
        @!WebSocket.outFrame = @!WebSocket.inFrame
        @!WebSocket.outFrame.opCode = WsOpCode.Pong.uint8
        
        await @!WebSocket.reply()

      # check if pong message same with socket hash id
      of WsOpCode.Pong.uint8:
        # close the connection if not valid
        if @!WebSocket.inFrame.encodeDecode() != @!WebSocket.hashId:
          @!WebSocket.state = WsState.Close
          @!WebSocket.statusCode = WsStatusCode.UnknownOpcode
          @!WebSocket.client.close

      of WsOpCode.ConnectionClose.uint8:
        @!WebSocket.state = WsState.Close
        @!WebSocket.statusCode = WsStatusCode.UnexpectedClose
        @!WebSocket.client.close

      else:
        discard

    of WsState.HandShake:
      # if State handshake
      # then send header handshake
      # send ping
      # set state to open
      # do handshake process
      let handshakeKey = @!WebSocket.
        handShakeReqHeaders.
        getValues("sec-websocket-key")[0].
        strip()

      try:
        await @!WebSocket.handShake(handshakeKey)
        @!WebSocket.statusCode = WsStatusCode.Ok

      except:
        @!WebSocket.state = WsState.Close
        @!WebSocket.statusCode = WsStatusCode.HandShakeFailed

    of WsState.Close:
      @!Trace:
        echo ""
        echo "#== start"
        echo "WebSocket closed."
        echo "#== end"
        echo ""

    # check if websocket uri in the routes
    # then do callback
    if @!WebSocket.state != WsState.HandShake and
      @!Routes.routeTable.hasKey(@!WebSocket.uri.getPath):
      await @!Routes.routeTable[@!WebSocket.uri.getPath]
        .thenDo(@!Context, @!Env)

    # discard all callback
    # only response websocket
    return true