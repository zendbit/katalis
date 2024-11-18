##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## add middleware on before route
## as http protocol handler
##


import std/
[
  httpcore,
  nativesockets,
  math
]


import
  ../../core/routes,
  ../../macros/sugar,
  ../../core/webSocket,
  ../../core/form,
  ../../core/environment


@!App:
  @!Before:
    #
    # http header parser request from client
    #
    var isRequestHeaderValid = true
    # for non websocket connection (http compliant)
    # only parse the header if websocket not initilaized
    # if nitialized indicate that websocket already connected
    if @!WebSocket.isNil:
      var line = await @!Client.recvLine()
      # if line empty indicate the header not valid
      # then return (exit from client handler)
      if line.strip == "":
        @!Client.close
        return

      let reqParts = line.strip().split(" ")
      # make sure header parts contain 3 parts (RFC 2616 HTTP Request-Uri)
      # first part is HTTP method
      # second part is location to request
      # third part is HTTP version
      # ex: GET http://www.w3.org/pub/WWW/TheProject.html HTTP/1.1
      if reqParts.len == 3:
        if HTTP_METHOD_TABLE.hasKey(reqParts[0]):
          @!Req.httpMethod = HTTP_METHOD_TABLE[reqParts[0]].code

        else:
          isRequestHeaderValid = false

        if isRequestHeaderValid:
          # parse uri request parts
          var protocol = "http"
          if @!Client.isSsl: protocol = "https"

          let (address, port) = @!Client.getLocalAddr
          @!Req.uri = parseUri3(reqParts[1])
          @!Req.uri.setScheme(protocol)
          @!Req.uri.setDomain(address)
          @!Req.uri.setPort($port)
          @!Req.httpVersion = reqParts[2]

      else:
        isRequestHeaderValid = false

    else:
      isRequestHeaderValid = false

    # parse general header
    while isRequestHeaderValid:
      var line = await @!Client.recvLine()
      let headers = line.strip().parseHeader
      let headerKey = headers.key.strip()
      let headerValue = headers.value

      if headerKey != "" and headerValue.len != 0:
        @!Req.headers[headerKey] = headerValue

        if headerKey.toLower() == "host":
          @!Req.uri.setDomain(headerValue.join(", ").split(":")[0])

      if line == CRLF:
        break

    var isErrorBodyContent = false
    # parse body
    if isRequestHeaderValid and
      @!Req.httpMethod in [HttpPost, HttpPut, HttpPatch, HttpDelete]:

      # get content length
      let bodyLen = @!Req.headers.contentLength
      # check body content
      if bodyLen != 0:
        # if body content larger than server can handle
        # return 413 code
        if bodyLen > @!Settings.maxRecvSize:
          @!Res.httpCode = Http413
          @!Res.headers["content-type"] = "application/json"
          @!Res.body = $ %newReplyMsg(
              httpCode = Http413,
              success = false,
              error = %*{"msg": &"Request larger than {bodyLen div (1024*1024)} MB not allowed."}
            )
          isErrorBodyContent = true

        else:
          if @!Req.headers.isFormMultipart:
            await @!Context.parseFormMultipart

          else:
            await @!Context.parseNonFormMultipart

      else:
        await @!Context.replyJson(
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
      await @!Context.replyJson(
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

