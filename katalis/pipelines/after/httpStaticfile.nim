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


import std/files


import
  ../../core/routes,
  ../../macros/sugar,
  ../../core/environment,
  ../../extension/httpStaticFile


@!App:
  @!After:
    # if not staticfile request then return false
    # to continue next after route chain
    if not @!Req.isStaticfile: return false

    # static path request location
    let requestStaticPath = @!Settings.staticDir/
      @!Req.uri.getPathSegments().
      join($DirSep).decodeUri().Path

    # return with reply sendFile with specific path
    await @!Context.replySendFile(requestStaticPath)
    return true
