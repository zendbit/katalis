##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## Websocket implementation
##


import std/
[
  random,
  times,
  asyncnet,
  httpcore,
  strformat,
  asyncdispatch
]
## std import

export
  random,
  times,
  asyncnet,
  httpcore,
  strformat,
  asyncdispatch
## std export


import sha1
import uri3
## nimble

export sha1
## nimble


import ../core/constants

export constants


type
  WsState* = enum ## \
    ## websocket state

    HandShake,
    Open,
    Close


  WsStatusCode* = enum ## \
    ## websocket status code

    Ok = 1000,
    GoingAway = 1001,
    BadProtocol = 1002,
    UnknownOpcode = 1003,
    BadPayload = 1007,
    ViolatesPolicy = 1008,
    PayloadToBig = 1009,
    HandShakeFailed = 1010
    UnexpectedClose = 1011


  WsOpCode* = enum ## \
    ## websocket operation code

    ContinuationFrame = 0x0
    TextFrame = 0x1
    BinaryFrame = 0x2
    ConnectionClose = 0x8
    Ping = 0x9
    Pong = 0xA


  WsFrame* = ref object of RootObj ## \
    ## websocket bit protocol frame

    fin*: uint8
    rsv1*: uint8
    rsv2*: uint8
    rsv3*: uint8
    opCode*: uint8
    mask*: uint8
    payloadLen*: uint64
    maskKey*: string
    payloadData*: string


  WebSocket* = ref object of RootObj ## \
    ## websocket object type

    client*: AsyncSocket
    uri*: Uri3
    state*: WsState
    inFrame*: WsFrame
    outFrame*: WsFrame
    statusCode*: WsStatusCode
    hashId*: string
    handShakeResHeaders*: HttpHeaders
    handShakeReqHeaders*: HttpHeaders


const WsMagicString* = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11" ## \
## websocket magic string


proc generateMaskKey(self: WsFrame) =
  ## generate mask key for handshake

  var maskKey = ""
  for i in 0..<4:
    maskKey &= chr(rand(254))

  self.mask = 0x1
  self.maskKey = maskKey


proc parseHeaders*(
    self: WsFrame,
    headers: string
  ) =
  ## parse websocket header

  # parse header of the websocket
  # HTTP/1.1 implementation in nim lang depend on RFC (https://tools.ietf.org/html/rfc2616)
  if headers.len != 0:
    let b0 = headers[0].uint8
    let b1 = headers[1].uint8

    self.fin = (b0 and 0x80) shr 7
    self.rsv1 = (b0 and (0x80 shr 1).uint8) shr 6
    self.rsv2 = (b0 and (0x80 shr 2).uint8) shr 5
    self.rsv3 = (b0 and (0x80 shr 3).uint8) shr 4
    self.opCode = b0 and 0x0f
    self.mask = (b1 and 0x80) shr 7
    self.payloadLen = (b1 and 0x7f)


proc parsePayloadLen*(
    self: WsFrame,
    payloadHeadersLen: string
  ) =
  ## parse websocket payload

  # parse playload header length
  # (message length)
  if payloadHeadersLen.len mod 2 == 0 and
    payloadHeadersLen.len != 0:

    var payloadLen:uint64 = 0
    var shiftL = high(payloadHeadersLen)

    for i in 0..high(payloadHeadersLen):
      payloadLen += payloadHeadersLen[i].uint64 shl (shiftL*8)
      dec(shiftL)

    self.payloadLen = payloadLen


proc encodeDecode*(self: WsFrame): string =
  ## encode decode message on websocket
  ## using xor encryption

  # xor encode decode
  # the standard encryption for the websocket
  if self.mask != 0x0:
    var decodedData = ""
    for i in 0..<self.payloadLen:
      decodedData &= chr(self.payloadData[i].uint8 xor self.maskKey[i mod 4].uint8)

    result = decodedData
  else:
    result = self.payloadData


proc toString*(self: WsFrame, mask: uint8 = 0x0): string =
  ## websocket frame to string representation

  self.mask = mask

  let data = self.encodeDecode()
  self.payloadLen = data.len.uint64

  # conver the websocket frame into string representation
  var payloadData = ""
  # fin(1)|rsv1(1)|rsv2(1)|rsv3(1)|opcode(4)
  payloadData &= chr(
      (self.fin shl 7) or
      (self.rsv1 shl 6) or
      (self.rsv2 shl 5) or
      (self.rsv3 shl 4) or
      self.opCode
    )

  # mask(1)|payloadlen(7)
  var payloadLenFlag: uint8
  var extPayloadLen: string

  if self.payloadLen.int >= 0x7e:
    # 16bit length
    if self.payloadLen <= high(uint16):
      payloadLenFlag = 0x7e
      for i in countdown(1, 0):
        extPayloadLen.add(chr((self.payloadLen shr (i*8)) and 0xff))

    # 64 bit length
    else:
      payloadLenFlag = 0x7f
      for i in countdown(7, 0):
        extPayloadLen.add(chr((self.payloadLen shr (i*8)) and 0xff))

  else:
    payloadLenFlag = self.payloadLen.uint8


  # add mask and payload len flag
  payloadData &= chr(
      (self.mask shl 7) or
      payloadLenFlag
    )

  # add extended payload len
  payloadData &= extPayloadLen

  # add mask if exist
  if self.mask == 0x1:
    payloadData &= self.maskKey

  # add the payload data
  payloadData &= data

  result = payloadData


proc newWsFrame*(
    payloadData: string,
    fin: uint8 = 0x1,
    opCode: uint8 = WsOpCode.TextFrame.uint8
  ): WsFrame {.gcsafe.} =
  ## create new websocket frame
  ## default fin is for onetime sending non continous
  ## opCode default is WsOpCode.TextFrame

  let instance = WsFrame(
      fin: fin,
      rsv1: 0, rsv2: 0, rsv3:0,
      opCode: opCode,
      payloadData: payloadData
    )

  # !!! this is may be raise as a bug
  # !!! let see if it works for large data set
  instance.payloadLen = payloadData.len.uint64
  instance.generateMaskKey()

  result = instance


proc newWebSocket*(
    client: AsyncSocket,
    state: WsState = WsState.HandShake,
    statusCode: WsStatusCode = WsStatusCode.HandShakeFailed
  ): WebSocket {.gcsafe.} =
  ## create new web socket
  ## default state is WsState.HandShake

  let hashId = now().utc().format("yyyy-MM-dd HH:mm:ss:ffffff".initTimeFormat)
  return WebSocket(
      state: state,
      statusCode: statusCode,
      hashId: compute(hashId).toBase64(),
      handShakeResHeaders: newHttpHeaders()
    )


proc handShake*(
    self: WebSocket,
    handShakeKey: string
  ) {.async gcsafe.} =
  ## create handshake with given handshake key

  # do handshake process
  if self.state == WsState.HandShake:
    if handShakeKey != "":
      var headers = ""
      headers &= &"{HttpVersion} 101 Switching Protocols{CrLf}"
      headers &= &"Server: {ServerId} {ServerVersion}{CrLf}"
      headers &= "Date: " &
        now().utc().format("ddd, dd MMM yyyy HH:mm:ss".initTimeFormat) & &" GMT{CrLf}"
      headers &= &"Connection: Upgrade{CrLf}"
      headers &= &"Upgrade: websocket{CrLf}"
      headers &= &"Sec-WebSocket-Accept: {compute(handShakeKey & WsMagicString).toBase64}{CrLf}"

      # additional handshake header
      for k, v in self.handShakeResHeaders.pairs:
        headers &= &"{k}: {v}{CrLf}"

      headers &= CrLf

      # send handshake response
      await self.client.send(headers)

    else:
      self.statusCode = WsStatusCode.HandShakeFailed


proc reply*(self: WebSocket) {.gcsafe async.} =
  ## send the websocket payload
  await self.client.send(self.outFrame.toString)


proc reply*(
    self: WebSocket,
    frame: WsFrame
  ) {.gcsafe async.} =
  ## send the websocket payload overwrite current outFrame with frame

  self.outFrame = frame
  await self.client.send(self.outFrame.toString)


proc reply*(
    self: WebSocket,
    msg: string,
    fin: uint8 = 0x1,
    opCode: uint8 = WsOpCode.TextFrame.uint8
  ) {.gcsafe async.} = ## \
  ## send websocket payload default is text frame

  await self.reply(newWsFrame(msg, fin, opCode))
