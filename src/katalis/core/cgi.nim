##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/nim_katalis
##

##
## cgi app implementation
##


import std/[
  syncio,
  envvars,
  httpcore,
  strtabs,
  strutils,
  paths,
  unicode
]
export
 syncio,
 envvars,
 httpcore,
 strtabs,
 strutils,
 paths,
 unicode

from std/nativesockets import Port
export Port


type
  CGI* = ref object of RootObj


proc newCGI*(): CGI {.gcsafe.} = ## \
  ## craate new Common Gateway Interface

  CGI()


proc gatewayInterface*(self: CGI): string {.gcsafe.} = ## \
  ## return GATEWAY_INTERFACE

  "GATEWAY_INTERFACE".getEnv


proc serverProtocol*(self: CGI): string {.gcsafe.} = ## \
  ## return SERVER_PROTOCOL

  "SERVER_PROTOCOL".getEnv


proc serverSoftware*(self: CGI): string {.gcsafe.} = ## \
  ## return SERVER_SOFTWARE

  "SERVER_SOFTWARE".getEnv


proc requestMethod*(self: CGI): HttpMethod {.gcsafe.} = ## \
  ## return REQUEST_METHOD as HttpMethod

  case "REQUEST_METHOD".getEnv
  of "HEAD": result = HttpHead
  of "GET": result = HttpGet
  of "POST": result = HttpPost
  of "PUT": result = HttpPut
  of "DELETE": result = HttpDelete
  of "TRACE": result = HttpTrace
  of "OPTIONS": result = HttpOptions
  of "CONNECT": result = HttpConnect
  of "PATCH": result = HttpPatch


proc scriptFilename*(self: CGI): Path {.gcsafe.} = ## \
  ## return SCRIPT_FILENAME

  "SCRIPT_FILENAME".getEnv.Path


proc queryString*(
    self: CGI
  ): tuple[query: string, attribute: StringTableRef] {.gcsafe.} = ## \
  ## return QUERY_STRING
  ## tuple[query: string, attribute: StringTableRef]

  let parts = newStringTable()
  let queryEnv = "QUERY_STRING".getEnv
  for qs in queryEnv.split("&"):
    let qsStrip = qs.strip
    if qsStrip == "": continue

    let qsPair = qsStrip.split("=")
    if qsPair.len != 1:
      parts[qsPair[0]] = qsPair[1]
      continue

    parts[qsPair[0]] = ""

  (queryEnv, parts)


proc scriptName*(self: CGI): Path {.gcsafe.} = ## \
  ## return SCRIPT_NAME

  "SCRIPT_NAME".getEnv.Path


proc documentRoot*(self: CGI): Path {.gcsafe.} = ## \
  ## return DOCUMENT_ROOT

  "DOCUMENT_ROOT".getEnv.Path


proc remoteAddr*(self: CGI): string {.gcsafe.} = ## \
  ## return REMOTE_ADDR

  "REMOTE_ADDR".getEnv


proc remotePort*(self: CGI): Port {.gcsafe.} = ## \
  ## return REMOTE_PORT

  "REMOTE_PORT".getEnv.parseUInt.uint16.Port


proc serverAddr*(self: CGI): string {.gcsafe.} = ## \
  ## return SERVER_ADDR

  "SERVER_ADDR".getEnv


proc serverName*(self: CGI): string {.gcsafe.} = ## \
  ## return SERVER_NAME

  "SERVER_NAME".getEnv


proc serverAdmin*(self: CGI): string {.gcsafe.} = ## \
  ## return SERVER_ADMIN

  "SERVER_ADMIN".getEnv


proc serverPort*(self: CGI): Port {.gcsafe.} = ## \
  ## return SERVER_PORT

  "SERVER_PORT".getEnv.parseUInt.uint16.Port


proc requestUri*(
    self: CGI
  ): tuple[
    uri: string,
    path: string,
    attribute: StringTableRef
  ] {.gcsafe.} = ## \
  ## return REQUEST_URI
  ## tuple[uri: string, path: string, attribute: StringTableRef]

  let uriEnv = "REQUEST_URI".getEnv
  (uriEnv, uriEnv.split("?")[0], self.queryString.attribute)


proc httpAccept*(self: CGI): string {.gcsafe.} = ## \
  ## return HTTP_ACCEPT

  "HTTP_ACCEPT".getEnv


proc contentType*(
    self: CGI
  ): tuple[
    raw: string,
    mimeType: string,
    attribute: StringTableRef
  ] {.gcsafe.} = ## \
  ## return CONTENT_TYPE
  ## tuple[raw: string, mimeType: string, attribute: StringTableRef]

  let contentTypeEnv = "CONTENT_TYPE".getEnv.split(";")
  let attribute = newStringTable()
  if contentTypeEnv.len > 1:
    for idx in 1..contentTypeEnv.high:
      let attributeKv = contentTypeEnv[idx].split("=")
      if attributeKv.len > 1:
        attribute[attributeKv[0].strip] = attributeKv[1].strip
        continue

      attribute[attributeKv[0].strip] = ""

  (contentTypeEnv.join(";"), contentTypeEnv[0].strip, attribute)


proc contentLength*(self: CGI): int {.gcsafe.} = ## \
  ## return CONTENT_LENGTH

  let contentLengthEnv = "CONTENT_LENGTH".getEnv.strip
  if contentLengthEnv == "": return 0
  contentLengthEnv.parseInt


proc httpHost*(self: CGI): string {.gcsafe.} = ## \
  ## return HTTP_HOST

  "HTTP_HOST".getEnv


proc httpUserAgent*(self: CGI): string {.gcsafe.} = ## \
  ## return HTTP_USER_AGENT

  "HTTP_USER_AGENT".getEnv


proc authType*(self: CGI): string {.gcsafe.} = ## \
  ## return AUTH_TYPE

  "AUTH_TYPE".getEnv


proc pathInfo*(self: CGI): Path {.gcsafe.} = ## \
  ## return PATH_INFO

  "PATH_INFO".getEnv.Path


proc pathTranslated*(self: CGI): Path {.gcsafe.} = ## \
  ## return PATH_TRANSLATED

  "PATH_TRANSLATED".getEnv.Path


proc remoteIdent*(self: CGI): string {.gcsafe.} = ## \
  ## return REMOTE_IDENT

  "REMOTE_IDENT".getEnv


proc requestHeaders*(self: CGI): HttpHeaders {.gcsafe.} = ## \
  ## return Request HttpHeaders

  result = newHttpHeaders()
  for (k, v) in envPairs():
    if not k.startsWith("HTTP_"): continue
    result[k.replace("HTTP_", "").toLower.replace("_", "-")] = v
