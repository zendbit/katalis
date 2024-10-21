##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## Constant use in system wide
##


import std/tables
from std/httpcore import HttpMethod


# server constants
const
  HttpVersion* = "HTTP/1.1" ## \
  ## http version header
  ServerId* = "katalis (Nim)" ## \
  ## server header identifier
  ServerVersion* = "0.1.0" ## \
  ## server build version

# utility
const
  CrLf* = "\c\L" ## \
  ## CrLf header token

  HttpMethodTable* = {
      "POST": (code: HttpPost, codeStr: "HttpPost"),
      "GET": (code: HttpGet, codeStr: "HttpGet"),
      "PUT": (code: HttpPut, codeStr: "HttpPut"),
      "DELETE": (code: HttpDelete, codeStr: "HttpDelete"),
      "OPTIONS": (code: HttpOptions, codeStr: "HttpOptions"),
      "PATCH": (code: HttpPatch, codeStr: "HttpPatch"),
      "HEAD": (code: HttpHead, codeStr: "HttpHead"),
      "CONNECT": (code: HttpConnect, codeStr: "HttpConnect"),
      "TRACE": (code: HttpTrace, codeStr: "HttpTrace")
    }.toTable

# flag
const
  WithSsl* = defined(ssl) or defined(nimdoc) ## \
  ## SSL checking enable or not
  IsReleaseMode = defined(release) or defined(nimdoc) ## \
  ## check production mode

when defined(release) or defined(nimdoc):
  const BuildMode = "relese"

else:
  const BuildMode = "debug"