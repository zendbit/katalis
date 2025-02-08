import
  ../core/[
    httpContext,
    environment
  ],
  httpChunked
export
  httpContext,
  environment

import strutils


proc initHttpRangesProperties*(self: HttpContext) {.gcsafe.} = ## \
  ## init http ranges properties

  if self.properties{"HttpRanges"}.isNil:
    self.properties["HttpRanges"] = %*{}


proc httpRangesProperties*(self: HttpContext): JsonNode {.gcsafe.} = ## \
  ## http ranges properties

  self.initHttpRangesProperties
  self.properties{"HttpRanges"}


proc parseHttpRangesFromHeader*(
    self: HttpContext,
    env: Environment = environment.instance()
  ): Future[bool] {.gcsafe async.} =
  # parse range request to HttpContext.ranges
  # seq[tuple(start: BiggestInt, stop: BiggestInt)]
  # parse range request
  # Range: bytes=0-1023, 2000-3000
  # Range: bytes=-500
  # Range: bytes=6000-
  # Range: 0-0, -1
  # see rfc about http ranges

  if not env.settings.enableRanges:
    self.response.headers["accept-ranges"] = "none"

  else:
    self.response.headers["accept-ranges"] ="bytes"
    self.httpRangesProperties["ranges"] = % @[]
    for rangesHeader in self.request.headers.getValues("range"):

      for ranges in rangesHeader.
        replace("bytes=", "").
        strip.
        split(","):

        if ranges.strip == "": continue

        var start, stop: Option[BiggestInt]

        if ranges.startsWith("-"):
          # parse bytes=-500
          start = some(ranges.strip.parseBiggestInt)

        elif ranges.endsWith("-"):
          # parse bytes=6000-
          start = some(ranges.strip.replace("-", "").parseBiggestInt)

        else:
          # parse bytes=0-500
          let rangeValues = ranges.split("-")
          if rangeValues.len == 2:
            start = some(rangeValues[0].strip.parseBiggestInt)
            stop = some(rangeValues[1].strip.parseBiggestInt)

        self.httpRangesProperties["ranges"].
          add(%*{"start": start, "stop": stop})


proc httpRanges*(
    self: HttpContext,
    bodySize: BiggestInt,
    env: Environment = environment.instance()
  ): seq[tuple[start: BiggestInt, stop: BiggestInt]] {.gcsafe.} =
  ## get seq[tuple[start: Option[BiggestInt], stop: Option[BiggestInt]]]
  ## to seq[tuple[start: BiggestInt, stop: BiggestInt]]

  if not self.httpRangesProperties{"ranges"}.isNil:
    let ranges = self.httpRangesProperties["ranges"].
      to(seq[tuple[start: Option[BiggestInt], stop: Option[BiggestInt]]])
    for (startOpt, stopOpt) in ranges:
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


proc replyRanges*[T: StaticFile|string](
    self: HttpContext,
    body: T,
    httpHeaders: HttpHeaders = nil,
    env: Environment = environment.instance()
  ) {.gcsafe async.} = ## \
  ## reply as ranges

  var headers = newHttpHeaders()
  var httpCode = Http200
  var contentBody = ""

  if not httpHeaders.isNil: headers &= httpHeaders

  when body is string:
    ## if body is string do string operation
    var mimeType = "application/octet-stream"
    if headers.getValues("Content-Type").len != 0:
      mimeType = headers.getValues("Content-Type")[0]
    headers["Content-Length"] = $body.len

    let ranges = self.httpRanges(body.len)
    if ranges.len == 0:
      if body.len <= env.settings.maxSendSize:
        contentBody = (await body.contents())[0]

      else:
        contentBody = (await body.contents(@[(0.int64, env.settings.maxSendSize.int64)]))[0]

    else:
      httpCode = Http206
      # for ranges request set httpcode to Http206
      # for continues request
      if ranges.len == 1:
        # single request only non multipart ranges
        let rangesData = await body.asBytesRanges(mimeType, ranges[0])
        contentBody = rangesData.content
        headers &= rangesData.headers

      else:
        # ranges with multipart
        let multipartRangesData = await body.asBytesRangesMultipart(mimeType, ranges)
        contentBody = multipartRangesData.content
        headers &= multipartRangesData.headers
      
  else:
    ## if body is static file then use file operation
    let ranges = self.httpRanges(body.info.size)

    headers["Content-Length"] = $body.info.size
    headers["Content-Type"] = body.mimetype
    if ranges.len == 0:
      if body.info.size <= env.settings.maxSendSize:
        contentBody = (await body.contents())[0]

      else:
        contentBody = (await body.contents(@[(0.int64, env.settings.maxSendSize.int64)]))[0]

    else:
      httpCode = Http206
      # for ranges request set httpcode to Http206
      # for continues request
      if ranges.len == 1:
        # single request only non multipart ranges
        let rangesData = await body.asBytesRanges(ranges[0])
        contentBody = rangesData.content
        headers &= rangesData.headers

      else:
        # ranges with multipart
        let multipartRangesData = await body.asBytesRangesMultipart(ranges)
        contentBody = multipartRangesData.content
        headers &= multipartRangesData.headers

  # return static file as response
  await self.reply(httpCode, contentBody, headers)
