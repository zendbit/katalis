##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## httpcore extensions
##


import
  std/[
    httpcore as std_httpcore,
    strutils,
    tables
  ]


proc `&`*(
    httpHeadersFirst: HttpHeaders,
    httpHeadersSecond: HttpHeaders
  ): HttpHeaders {.gcsafe.} =
  ## merge http headers

  result = httpHeadersFirst
  if result.isNil: result = newHttpHeaders()

  if not httpHeadersSecond.isNil:
    for k, v in httpheadersSecond:
      if result.getOrDefault(k) != "": continue
      result.add(k, v)


proc `&=`*(
    httpHeadersFirst: var HttpHeaders,
    httpHeadersSecond: HttpHeaders
  ) {.gcsafe.} =
  ## merge http headers
  ## and save result to httpHeadersFirst

  if httpHeadersFirst.isNil:
    httpHeadersFirst = newHttpHeaders()

  if not httpHeadersSecond.isNil:
    for k, v in httpHeadersSecond:
      httpHeadersFirst.add(k, v)


proc getValues*(
    httpHeaders: HttpHeaders,
    key: string
  ): seq[string] =
  ## get seq of HttpHeader values

  result = @[]

  let k = key.strip()
  if httpHeaders.table.hasKey(k.toLower()):
    result = httpHeaders.table[k.toLower()]

  if httpHeaders.table.hasKey(k):
    result = httpHeaders.table[k]


proc contentLength*(headers: HttpHeaders): BiggestInt {.gcsafe.} =
  ## get content length

  try:
    let length = headers.getValues("content-length")
    if length.len != 0: result = length[0].parseBiggestInt

  except CatchableError:
    discard


proc contentType*(headers: HttpHeaders): string {.gcsafe.} =
  ## get content type

  let content = headers.getValues("content-type")
  if content.len != 0: result = content[0]


proc multipartBoundary*(
    headers: HttpHeaders
  ): tuple[start: string, stop: string] {.gcsafe.} =
  ## get multipar boundary
  ## return tuple boundary start and boundary stop
  
  var startBoundary, endBoundary = ""
  for findBoundary in headers.contentType.split(";"):
    if findBoundary.contains("boundary="):
      startBoundary = "--" & findBoundary.
        replace("boundary=", "").strip
      endBoundary = startBoundary & "--"
      result = (startBoundary, endBoundary)
      break


proc isJson*(headers: HttpHeaders): bool {.gcsafe.} =
  ## check if headers content type is json
  
  headers.contentType.toLower.contains("/json")


proc isXml*(headers: HttpHeaders): bool {.gcsafe.} =
  ## check if headers content type is xml
  
  headers.contentType.toLower.contains("/xml")


proc isFormUrlencoded*(headers: HttpHeaders): bool {.gcsafe.} =
  ## check if headers content type is x-www-form-urlencoded
  
  headers.contentType.toLower.contains("/x-www-form-urlencoded")


proc isFormMultipart*(headers: HttpHeaders): bool {.gcsafe.} =
  ## check if headers content type is form-data multipart

  headers.contentType.toLower.contains("/form-data")
