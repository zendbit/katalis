import
  ../core/[
    httpContext,
    environment,
    routes
  ],
  ../utils/debug
export
  httpContext,
  environment,
  routes

import
  strformat,
  strutils


proc parseWebSocketRequest*(
    self: HttpContext,
    env: Environment = environment.instance()
  ): Future[bool] {.gcsafe async.} = ## \
  ## parse websocket request

  # if header key containts upgrade websocket then the request is websocket
  # websocket only accept get method
  if self.webSocket.isNil:
    let upgradeProtocol =  self.request.headers.getValues("upgrade")
    if "websocket" in upgradeProtocol and self.request.httpMethod == HttpGet:

      if self.request.uri.getScheme() == "http":
        self.request.uri.setScheme("ws")

      else:
        self.request.uri.setScheme("wss")

      self.webSocket = newWebSocket(
          client = self.client,
          state = WsState.HandShake
        )

      self.webSocket.uri = self.request.uri
      self.webSocket.client = self.client
      self.webSocket.handShakeReqHeaders = self.request.headers

  # if websocket still nil then return
  # don't evaluate rest of websocket handler
  if self.webSocket.isNil:
    return

  # check if state is handshake and
  # status code ok
  # if handshake success the change state to open
  if self.webSocket.state == WsState.HandShake and
    self.webSocket.statusCode == WsStatusCode.Ok:
    self.webSocket.state = WsState.Open

  case self.webSocket.state
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
    self.webSocket.statusCode = WsStatusCode.Ok
    # create websocket frame
    # set websocket input frame
    self.webSocket.inFrame = WSFrame()

    # get header first 2 bytes
    let header = await self.webSocket.client.recv(2)
    # make sure header containt 2 bytes (string with len 2)
    if header.len == 2 and header.strip() != "":
      # parse the headers frame
      self.webSocket.inFrame.parseHeaders(header)

      # if payload len 126 (0x7e)
      # get the length of the data from the
      # next 2 bytes
      # get extended payload length next 2 bytes
      if self.webSocket.inFrame.payloadLen == 0x7e:
        self.webSocket.inFrame.parsePayloadLen(await self.webSocket.client.recv(2))
      # if payload len 127 (0x7f)
      # get the length of the data from the
      # next 8 bytes
      # get extended payload length next 8 bytes
      elif self.webSocket.inFrame.payloadLen == 0x7f:
        self.webSocket.inFrame.parsePayloadLen(await self.webSocket.client.recv(8))

      # check if the payload len is not larget than allowed max
      # max is maxRecvSize
      # if payloadLen larget than max int then
      # send error and
      if self.webSocket.inFrame.payloadLen <= env.settings.maxRecvSize.uint64:
        # if isMasked then get the mask key
        # next 4 bytes (uint32)
        if self.webSocket.inFrame.mask != 0x0:
          self.webSocket.inFrame.maskKey = await self.webSocket.client.recv(4)

        # get payload data
        # asyncnet.recv(int32) only accept int32
        # payloadLen is uint64, we need to retrieve in part of int32
        if self.webSocket.inFrame.payloadLen != 0:
          self.webSocket.inFrame.payloadData = ""
          var retrieveCount = (self.webSocket.inFrame.payloadLen div high(int32).uint64).uint64

          if retrieveCount == 0:
            self.webSocket.inFrame.payloadData = await self.webSocket.client.recv(self.webSocket.inFrame.payloadLen.int32)

          else:
            let restToRetrieve = self.webSocket.inFrame.payloadLen mod high(int32).uint64
            for i in 0..retrieveCount:
              self.webSocket.inFrame.payloadData &= await self.webSocket.client.recv(high(int32))

            if restToRetrieve != 0:
              self.webSocket.inFrame.payloadData &= await self.webSocket.client.recv(restToRetrieve.int32)

      else:
        self.webSocket.state = WsState.Close
        self.webSocket.statusCode = WsStatusCode.PayloadTooBig
        self.webSocket.errMsg = "Payload is too big."
        self.webSocket.client.close

    else:
      self.webSocket.state = WsState.Close
      self.webSocket.statusCode = WsStatusCode.BadPayload
      self.webSocket.errMsg = "Bad payload."
      self.webSocket.client.close


    case self.webSocket.inFrame.opCode
    # response the ping with same message buat change the opcode to pong
    of WsOpCode.Ping.uint8:
      self.webSocket.outFrame = self.webSocket.inFrame
      self.webSocket.outFrame.opCode = WsOpCode.Pong.uint8

      await self.webSocket.reply()

    # check if pong message same with socket hash id
    of WsOpCode.Pong.uint8:
      # close the connection if not valid
      if self.webSocket.inFrame.encodeDecode() != self.webSocket.hashId:
        self.webSocket.state = WsState.Close
        self.webSocket.statusCode = WsStatusCode.UnknownOpcode
        self.webSocket.errMsg = "Unknown opcode."
        self.webSocket.client.close

    of WsOpCode.ConnectionClose.uint8:
      self.webSocket.state = WsState.Close
      self.webSocket.statusCode = WsStatusCode.UnexpectedClose
      self.webSocket.errMsg = "Unexpected close."
      self.webSocket.client.close

    else:
      discard

  of WsState.HandShake:
    # if State handshake
    # then send header handshake
    # send ping
    # set state to open
    # do handshake process
    let handshakeKey = self.webSocket.
      handShakeReqHeaders.
      getValues("sec-websocket-key")[0].
      strip()

    try:
      await self.webSocket.handShake(handshakeKey)
      self.webSocket.statusCode = WsStatusCode.Ok

    except CatchableError, Defect:
      self.webSocket.state = WsState.Close
      self.webSocket.statusCode = WsStatusCode.HandShakeFailed
      self.webSocket.errMsg = "Handshake failed."
      self.webSocket.client.close
      await putLog "Websocket handshake failed " & getCurrentExceptionMsg()

  of WsState.Close:
    @!Trace:
      echo ""
      echo "#== start"
      echo "WebSocket closed."
      echo "#== end"
      echo ""

  # check if websocket uri in the routes
  # then do callback
  let webSocketRoute = routes.instance().findRoute(
      self.webSocket.uri.getPath
    )

  if self.webSocket.state != WsState.HandShake and
    not webSocketRoute.isNil:
    await webSocketRoute.thenDo(self, env)

  # discard all callback
  # only response websocket
  return true
