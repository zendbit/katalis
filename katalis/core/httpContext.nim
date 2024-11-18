##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## HttpContext handle response request
##


import std/
[
  asyncnet,
  httpcore,
  asyncdispatch,
  strutils,
  tables,
  json,
  xmltree,
  options,
  math,
  cookies,
  strtabs
]
## std import

export
  asyncnet,
  httpcore,
  asyncdispatch,
  options
## std export


import uri3
## nimble

export uri3
## nimble


import
  constants,
  webSocket,
  ../utils/httpcore as utilsHttpCore,
  replyMsg,
  environment,
  staticFile,
  request,
  response

export
  constants,
  webSocket,
  replymsg,
  staticfile,
  utilsHttpCore,
  request,
  response


const CookieDateFormat = "ddd, dd MMM yyyy HH:mm:ss"

type
  HttpContext* = ref object of RootObj
    ## HttpContext object, context on http each request/response

    request*: Request ## \
    ## Request type instance
    client*: AsyncSocket ## \
    ## client asyncsocket for communicating to client
    response*: Response ## \
    ## Response type instance
    webSocket*: WebSocket ## \
    ## webSocket parameter context
    onreply*: proc (
        self: HttpContext,
        env: Environment = environment.instance()
      ) {.gcsafe async.} ## \
    ## onreply action
    ## this code will execute before data send to client


proc getRanges*(
    self: Request,
    bodySize: BiggestInt,
    env: Environment = environment.instance()
  ): seq[tuple[start: BiggestInt, stop: BiggestInt]] {.gcsafe.} =
  ## get seq[tuple[start: Option[BiggestInt], stop: Option[BiggestInt]]]
  ## to seq[tuple[start: BiggestInt, stop: BiggestInt]]

  for (startOpt, stopOpt) in self.ranges:
    var start, stop: BiggestInt
    start = startOpt.get(0)

    if stopOpt.isNone:
      if start < 0:
        start = bodySize + start
        stop = bodySize - 1
      else:
        stop = start + env.settings.rangesSize - 1
    else:
      stop = stopOpt.get(env.settings.rangesSize - 1)

    result.add((start, stop))


proc cleanUri*(
    path: string
  ): tuple[origin: string, clean: string] {.gcsafe.} =
  ## clean the path if at the and of path contains /
  ## remove the / from the end of path
  ## return origin and clean uri

  var uri = path
  if uri.endsWith("/") and path != "/":
    uri.removeSuffix("/")
  
  (path, uri)


proc clear*(self: HttpContext) {.gcsafe.} =
  ## clear the context for next persistent connection

  self.request = newRequest()
  self.response = newResponse()


proc newHttpContext*(
    client: AsyncSocket,
    request: Request = newRequest(),
    response: Response = newResponse(body = "")
  ): HttpContext {.gcsafe.} =
  ## create HttpContext instance
  ## this will be the main HttpContext
  ## will be contain:
  ##  client -> is the asyncsocket of connected client
  ##  request -> is the request from client
  ##  response -> is the response from server

  HttpContext(
    client: client,
    request: request,
    response: response
  )


proc isKeepAlive*(
    self: HttpContext,
    env: Environment = environment.instance()
  ): bool {.gcsafe.} =
  ## check if the server using keepalive mode or not

  let keepAliveHeader =
    self.
      request.
      headers.
      getValues("connection")

  if "close" notin keepAliveHeader and
    "keep-alive" in keepAliveHeader and
    env.settings.enableKeepAlive:

    result = true


proc reply*(
    self: HttpContext,
    env: Environment = environment.instance()
  ) {.gcsafe async.} =
  ## send response to client socket directly
  ## through socket instance context.client

  ## after route call here
  ## for modification before send to client
  ## bind using onreply
  ## see pipelines/http_routes
  if not self.onreply.isNil:
    await self.onreply(self, env)

  if not self.client.isClosed:
    await self.client.send(self.response.body)

  if not self.isKeepAlive:
    self.client.close


proc reply*(
    self: HttpContext,
    httpCode: HttpCode,
    body: string,
    httpHeaders: HttpHeaders = nil
  ) {.gcsafe async.} =
  ## send response

  self.response.headers &= httpHeaders
  if self.response.headers.getValues("content-type").len == 0: ## \
    ## set default value content-type to text/html
    ## if not set yet
    self.response.headers["content-type"] = "text/html"
  self.response.httpCode = httpCode
  self.response.body = body

  await self.reply()


proc replyJson*(
    self: HttpContext,
    httpCode: HttpCode,
    body: JsonNode,
    httpHeaders: HttpHeaders = nil
  ) {.gcsafe async.} =
  ## send http resp as json

  let headers = newHttpHeaders()
  headers["content-type"] = "application/json"

  await self.reply(httpCode, $body, headers & httpHeaders)


proc reply*(
    self: HttpContext,
    msg: ReplyMsg,
    httpHeaders: HttpHeaders = nil
  ) {.gcsafe async.} =
  ## send http resp as json

  let headers = newHttpHeaders()
  headers["content-type"] = "application/json"

  await self.replyJson(msg.httpCode, %msg, headers & httpHeaders)


proc replyXml*(
    self: HttpContext,
    httpCode: HttpCode,
    body: XmlNode,
    httpHeaders: HttpHeaders = nil
  ) {.gcsafe async.} =
  ## send http resp as xml

  let headers = newHttpHeaders()
  headers["content-type"] = "application/xml"

  await self.reply(httpCode, $body, headers & httpHeaders)


proc replyOctetStream*(
    self: HttpContext,
    httpCode: HttpCode,
    body: string,
    httpHeaders: HttpHeaders = nil
  ) {.gcsafe async.} =
  ## send http resp as xml

  let headers = newHttpHeaders()
  headers["content-type"] = "application/octet-stream"

  await self.reply(httpCode, body, headers & httpHeaders)


proc parseFormMultipart*(
    self: HttpContext,
    env: Environment = environment.instance()
  ) {.gcsafe async.} =
  ## parse form multipart
  # try get form multipart boundary

  type ParseStep = enum
    ParseHeader
    ParseContent

  let req = self.request
  let settings = env.settings
  let client = self.client

  let boundary = req.headers.multipartBoundary
  if boundary.start == "": return

  # if any remain len to buff
  var remainToBuff = 0
  # number of req.body to recv
  var numOfBuff = 0
  let bodyLen = req.headers.contentLength

  # calculate remain req.body and num req.body
  # if bodyLen larger than readRecvBuffer
  if bodyLen > settings.readRecvBuffer:
    numOfBuff = floor(bodyLen / settings.readRecvBuffer).int
    remainToBuff = bodyLen mod settings.readRecvBuffer

  let formData = newForm()
  let crlf = &"{CRLF}"
  var isParseMultipart = false
  var filename = ""
  var metaName = ""
  var contentType = ""
  var parseStep = ParseHeader

  for i in 0..numOfBuff:
    if i == numOfBuff and remainToBuff != 0:
      req.body &= await client.recv(remainToBuff)
    elif bodyLen < settings.readRecvBuffer:
      req.body &= await client.recv(bodyLen)
    else:
      req.body &= await client.recv(settings.readRecvBuffer)

    let crlfIndex = proc (): int = req.body.find(crlf)
    let boundaryStartIndex = proc (): int = req.body.find(boundary.start)
    let boundaryEndIndex = proc (): int = req.body.find(boundary.stop)

    while boundaryStartIndex() != -1:
      if boundaryStartIndex() == 0 and crlfIndex() != -1:
        if boundaryEndIndex() == 0:
          req.body = ""
        else:
          req.body = req.body.substr(boundary.start.len + crlf.len, req.body.high)

        if filename != "" and metaName != "":
          await formData.files[metaName][^1].file.write("\n")
          formData.files[metaName][^1].close()
          formData.files[metaName][^1].isAccessible = formData.files[metaName][^1].path.fileExists

        filename = ""
        metaName = ""
        contentType = ""
        parseStep = ParseHeader

      elif parseStep == ParseHeader:
        if crlfIndex() == 0:
          req.body = req.body.substr(crlf.len, req.body.high)
          parseStep = ParseContent
          continue

        let data = req.body.substr(0, crlfIndex())

        if data.toLower.startsWith("content-disposition"):
          for metaList in data.split(";"):
            let meta = metaList.split("=")
            if meta.len == 2:
              let metaKey = meta[0].strip
              let metaValue = meta[1].strip
              if metaKey == "name":
                metaName = metaValue.replace("\"", "").replace("[]", "")
              if metaKey == "filename":
                filename = metaValue.replace("\"", "")

          if filename != "":
            formData.addFile(
              metaName,
              newStaticFile(
                settings.storagesUploadDir.joinPath(filename)
              )
            )

            formData.files[metaName][^1].mimeType = contentType
            formData.files[metaName][^1].open(fmWrite)
            formData.files[metaName][^1].name = filename

          else:
            formData.data[metaName] = ""

        elif data.toLower.startsWith("content-type"):
          for metaList in data.split(";"):
            let meta = metaList.split(":")
            if meta.len == 2:
              let metaKey = meta[0].strip
              let metaValue = meta[1].strip
              if metaKey.toLower == "content-type":
                contentType = metaValue

          if filename != "":
            formData.files[metaName][^1].mimeType = contentType
            formData.files[metaName][^1].extension = filename.splitFile.ext

        req.body = req.body.substr(crlfIndex() + crlf.len, req.body.high)

      elif parseStep == ParseContent:
        if crlfIndex() == 0:
          req.body = req.body.substr(crlf.len, req.body.high)
          continue

        var data = req.body
        if boundaryStartIndex() != -1:
          data = req.body.substr(0, boundaryStartIndex() - crlf.len)
          req.body = req.body.substr(boundaryStartIndex(), req.body.high)

        if filename != "" and contentType != "":
          await formData.files[metaName][^1].file.write(data)

        else:
          formData.data[metaName] &= data

  # set context request paramter
  req.param.form = formData


proc parseJson*(
    self: HttpContext,
    env: Environment = environment.instance()
  ) {.gcsafe async.} =
  ## parse json request from client

  let req = self.request

  try:
    req.param.json = req.body.parseJson
  except Exception as ex:
    await self.replyJson(
        Http400,
        %newReplyMsg(
          Http400,
          success = false,
          error = %*{"msg": ex.msg}
        )
      )


proc parseXml*(
    self: HttpContext,
    env: Environment = environment.instance()
  ) {.gcsafe async.} =
  ## parse json request from client

  let req = self.request

  try:
    req.param.xml = req.body.parseXml
  except Exception as ex:
    await self.replyJson(
        Http400,
        %newReplyMsg(
          Http400,
          success = false,
          error = %*{"msg": ex.msg}
        )
      )


proc parseFormUrlencoded*(
    self: HttpContext,
    env: Environment = environment.instance()
  ) {.gcsafe async.} =

    # collect form data urlencoded from client
    let formData = newForm()
    let req = self.request
    for data in req.body.
      decodeUri().split("&"):
      let kv = data.split("=")
      if kv.len == 2:
        formData.addData(kv[0].strip, kv[1].strip)

    if formData.data.len != 0:
      req.param.form = formData


proc parseNonFormMultipart*(
    self: HttpContext,
    env: Environment = environment.instance()
  ) {.gcsafe async.} =
  ## parse request parameter content to json


  let settings = env.settings
  let client = self.client
  let req = self.request

  var bodyLen = req.headers.contentLength
  if bodyLen > settings.maxBodySize:
    bodyLen = settings.maxBodySize

  if bodyLen <= settings.readRecvBuffer:
    req.body = await client.recv(bodyLen)
  else:
    let remainBodyLen = bodyLen mod settings.readRecvBuffer
    let toBuff = floor(bodyLen / settings.readRecvBuffer).int

    for i in 0..toBuff:
      if i < toBuff - 1:
        req.body = await client.recv(settings.readRecvBuffer)
      elif remainBodyLen != 0:
        req.body = await client.recv(remainBodyLen)

  if req.headers.isJson:
    await self.parseJson
    
  elif req.headers.isXml:
    await self.parseXml

  elif req.headers.isFormUrlEncoded:
    await self.parseFormUrlencoded


proc toCookieDateFormat*(dt: DateTime): string = ## \
  ##
  ##  convert datetime to cookie date format
  ##  ddd, dd MMM yyyy HH:mm:ss GMT
  ##
  result = dt.format(CookieDateFormat) & " GMT"


proc parseFromCookieDateFormat*(st: string): DateTime = ## \
  ##
  ##  parse cookie string date format to datetime
  ##
  result = parse(st.replace("GMT", "").strip, CookieDateFormat)


proc setCookie*(
  self: HttpContext,
  cookies: StringTableRef,
  domain: string = "",
  path: string = "/",
  expires: string = "",
  secure: bool = false,
  sameSite: string = "Lax",
  httpOnly: bool = true) = ## \
  ##
  ##  create cookie
  ##
  ##  cookies is StringTableRef
  ##  setCookie({"username": "bond"}.newStringTable)
  ##
  var cookieList: seq[string] = @[]
  for k, v in cookies:
    cookieList.add(k & "=" & v)

  if domain != "":
    cookieList.add("domain=" & domain)
  
  if path != "":
    cookieList.add("path=" & path)

  if expires == "":
    cookieList.add("expires=" & (now().utc + 7.days).toCookieDateFormat)

  else:
    cookieList.add("expires=" & expires)

  cookieList.add("SameSite=" & sameSite)

  if secure:
    cookieList.add("Secure")

  if httpOnly:
    cookieList.add("HttpOnly")

  self.response.headers.add("Set-Cookie", join(cookieList, ";"))


proc getCookie*(self: HttpContext): StringTableRef = ## \
  ##
  ##  get cookie:
  ##
  ##  get cookies, return StringTableRef
  ##  if self.getCookies().hasKey("username"):
  ##    dosomethings
  ##
  var cookie = self.request.headers.getOrDefault("cookie")
  if cookie != "":
    return parseCookies(cookie)

  result = newStringTable()


proc clearCookie*(
  self: HttpContext,
  cookies: StringTableRef) = ## \
  ##
  ##  clear cookie:
  ##
  ##  let cookies = self.getCookies
  ##  self.clearCookie(cookies)
  ##
  self.setCookie(cookies, expires = "Thu, 01 Jan 1970 00:00:00 GMT")
