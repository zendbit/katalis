##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## Pipeline for http static file
## accept-ranges: bytes
## will be return from before/http_ranges.nim
## if range accepted will handle here
## request with range like:
## bytes=0-
## bytes=7000-
## bytes=-7000
## bytes=100-7000
## bytes=100-7000, 10000-80000
## see http rfc about ranges bytes section
##


import
  ../../core/routes,
  ../../macros/sugar,
  ../../core/environment


@!App:
  @!After:
    # if not staticfile request then return false
    # to continue next after route chain
    if not @!Req.isStaticfile: return false

    # static path request location
    var requestStaticPath = @!Req.
      uri.
      getPathSegments().
      join($DirSep).decodeUri()

    # construct static path dir with request static path
    requestStaticPath = @!Settings.
      staticDir.
      joinPath(
        requestStaticPath
      )

    # create static file route is static file
    let staticFile = newStaticFile(requestStaticPath)

    # file not accessible then return false
    # to continue other pipeline chain
    if not staticFile.isAccessible: return false

    # create ranges if request using Ranges: header
    let ranges = @!Req.getRanges(staticFile.info.size)

    var headers = newHttpHeaders()
    var httpCode = Http200
    var contentBody = ""

    if ranges.len == 0:
      headers["content-type"] = staticFile.mimetype
      headers["content-length"] = &"{staticFile.info.size}"
      contentBody =
        if staticFile.info.size < @!Settings.maxSendSize:
          (await staticFile.contents())[0]

        else:
          (
            await staticFile.contents(
              @[(0.int64, @!Settings.maxSendSize.int64 - 1)]
            )
          )[0]

    else:
      # for ranges request set httpcode to Http206
      # for continues request
      httpCode = Http206
      if ranges.len == 1:
        # single request only non multipart ranges
        let rangesData = await staticFile.
          contentsAsBytesRanges(ranges[0])
        contentBody = rangesData.content
        headers &= rangesData.headers

      else:
        # ranges with multipart
        let multipartRangesData = await staticFile.
          contentsAsBytesRangesMultipart(ranges)

        contentBody = multipartRangesData.content
        headers &= multipartRangesData.headers

    # return static file as response
    await @!Context.reply(httpCode, contentBody, headers)
    # return true break other after route sequence
    return true
