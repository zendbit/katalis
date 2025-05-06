import 
  ../core/[
    httpContext,
    environment
  ]
export
  httpContext,
  environment

import
  strformat,
  strutils,
  nativesockets


when not CgiApp:
  proc parseHttpRequest*(
    self: HttpContext,
    env: Environment = environment.instance()
  ): Future[bool] {.gcsafe async.} = ## \
    ## parse request from client
    ## parse header from client

    #
    # http header parser request from client
    #
    var isRequestHeaderValid = true
    # for non websocket connection (http compliant)
    # only parse the header if websocket not initilaized
    # if nitialized indicate that websocket already connected
    if self.webSocket.isNil:
      var line = await self.client.recvLine()
      # if line empty indicate the header not valid
      # then return (exit from client handler)
      if line.strip == "":
        self.client.close
        return

      let reqParts = line.strip().split(" ")
      # make sure header parts contain 3 parts (RFC 2616 HTTP Request-Uri)
      # first part is HTTP method
      # second part is location to request
      # third part is HTTP version
      # ex: GET http://www.w3.org/pub/WWW/TheProject.html HTTP/1.1
      if reqParts.len == 3:
        if HTTP_METHOD_TABLE.hasKey(reqParts[0]):
          self.request.httpMethod = HTTP_METHOD_TABLE[reqParts[0]].code

        else:
          isRequestHeaderValid = false

        if isRequestHeaderValid:
          # parse uri request parts
          var protocol = "http"
          if self.client.isSsl: protocol = "https"

          let (address, port) = self.client.getLocalAddr
          self.request.uri = parseUri3(reqParts[1])
          self.request.uri.setScheme(protocol)
          self.request.uri.setDomain(address)
          self.request.uri.setPort($port)
          self.request.httpVersion = reqParts[2]

      else:
        isRequestHeaderValid = false

    else:
      isRequestHeaderValid = false

    # parse general header
    while isRequestHeaderValid:
      var line = await self.client.recvLine()
      let headers = line.strip().parseHeader
      let headerKey = headers.key.strip()
      let headerValue = headers.value

      if headerKey != "" and headerValue.len != 0:
        self.request.headers[headerKey] = headerValue

        if headerKey.toLower() == "host":
          self.request.uri.setDomain(headerValue.join(", ").split(":")[0])

      if line == CRLF:
        break

    var isErrorBodyContent = false
    # parse body
    if isRequestHeaderValid and
      self.request.httpMethod in [HttpPost, HttpPut, HttpPatch, HttpDelete]:

      # get content length
      let bodyLen = self.request.headers.contentLength
      # check body content
      if bodyLen != 0:
        # if body content larger than server can handle
        # return 413 code
        if bodyLen > env.settings.maxRecvSize:
          self.response.httpCode = Http413
          self.response.headers["content-type"] = "application/json"
          self.response.body = $ %newReplyMsg(
              httpCode = Http413,
              success = false,
              error = %*{"msg": &"Request larger than {bodyLen div (1024*1024)} MB not allowed."}
            )
          isErrorBodyContent = true

        else:
          if self.request.headers.isFormMultipart:
            await self.parseFormMultipart

          else:
            await self.parseNonFormMultipart

      else:
        await self.replyJson(
          Http411,
          %newReplyMsg(
            Http411,
            success = false,
            error = %*{"msg": "content length required!"}
          )
        )
        # return true for skip all other
        # if any error occured
        return true

    if isErrorBodyContent:
      await self.replyJson(
        Http400,
        %newReplyMsg(
          Http400,
          success = false,
          error = %*{"msg": "Bad request!"}
        )
      )
      # return true for skip all other
      # if any error occured
      return true


  proc composeHttpPayload*(
      self: HttpContext,
      env: Environment = environment.instance()
    ) {.gcsafe async.} = ## \
    ## compose payload for http response

    # add server info into header
    var header = ""
    header &= &"{HttpVersion} {self.response.httpCode}{CrLf}"
    header &= &"server: {ServerId} {ServerVersion}{CrLf}"

    # add server date info
    self.response.headers["date"] = now().
      utc().
      format("ddd, dd MMM yyyy HH:mm:ss".
      initTimeFormat) & " GMT"

    # check if connection support keepalive
    if self.isKeepAlive:
      self.response.headers["connection"] = "keep-alive"

    else:
      self.response.headers["connection"] = "close"

    if "chunked" in self.response.headers.getValues("transfer-encoding"):
      self.response.headers.del("content-length")
    else:
      ## if content not chunked transfer encoding
      self.response.headers["content-length"] =  &"{self.response.body.len}"

    # add additional headers into response header
    for k, v in self.response.headers.pairs:
      header &= &"{k}: {v}{CrLf}"

    header &= CrLf

    if self.request.httpMethod == HttpHead:
      self.response.body = header

    else:
      self.response.body = header & self.response.body

else:
  ## build for CgiApp
  proc parseHttpRequest*(
    self: HttpContext,
    env: Environment = environment.instance()
  ): Future[bool] {.gcsafe async.} = ## \
    ## parse request from client
    ## parse header from client

    self.request.httpMethod = self.cgi.requestMethod
    self.request.headers = self.cgi.requestHeaders
    var protocol =
      if "1" in self.request.headers.
        getValues("Upgrade-Insecure-Requests"):
        "http"
      else:
        "https"

    self.request.uri = parseUri3(
        protocol & "://" & self.cgi.serverName &
        ":" & $self.cgi.serverPort &
        self.cgi.requestUri.uri
      )

    self.request.httpVersion = self.cgi.serverProtocol
    self.request.headers["Content-Length"] = $self.cgi.contentLength
    self.request.headers["Authorization"] = self.cgi.authType
    self.request.headers["Content-Type"] = self.cgi.contentType.raw

    var isErrorBodyContent = false
    # parse body
    if self.request.httpMethod in
      [HttpPost, HttpPut, HttpPatch, HttpDelete]:
      # get content length
      let bodyLen = self.request.headers.contentLength
      # check body content
      if bodyLen != 0:
        # if body content larger than server can handle
        # return 413 code
        if bodyLen > env.settings.maxRecvSize:
          self.response.httpCode = Http413
          self.response.headers["content-type"] = "application/json"
          self.response.body = $ %newReplyMsg(
              httpCode = Http413,
              success = false,
              error = %*{"msg": &"Request larger than {bodyLen div (1024*1024)} MB not allowed."}
            )
          isErrorBodyContent = true

        else:
          if self.request.headers.isFormMultipart:
            await self.parseFormMultipart

          else:
            await self.parseNonFormMultipart

      else:
        await self.replyJson(
          Http411,
          %newReplyMsg(
            Http411,
            success = false,
            error = %*{"msg": "content length required! "}
          )
        )
        # return true for skip all other
        # if any error occured
        return true

    if isErrorBodyContent:
      await self.replyJson(
        Http400,
        %newReplyMsg(
          Http400,
          success = false,
          error = %*{"msg": "Bad request!"}
        )
      )
      # return true for skip all other
      # if any error occured
      return true


  proc composeHttpPayload*(
      self: HttpContext,
      env: Environment = environment.instance()
    ) {.gcsafe async.} = ## \
    ## compose payload for http response

    # add server info into header
    var header = ""

    ## make sure if build for CgiApp
    ## remove content-length
    ## should be set by web server
    self.response.headers.del("content-length")

    # add additional headers into response header
    for k, v in self.response.headers.pairs:
      header &= &"{k}: {v}{CrLf}"

    header &= CrLf

    if self.request.httpMethod == HttpHead:
      self.response.body = header

    else:
      self.response.body = header & self.response.body
