##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## Request type implementation
##


import
  std/httpcore,
  json
## std import
export
  httpcore,
  json
## std export


type
  Response* = ref object of RootObj
    ## Response type
    httpCode*: HttpCode ## \
    ## httpcode response to client
    headers*: HttpHeaders ## \
    ## headers response to client
    body*: string ## \
    ## body response to client


proc newResponse*(
    httpCode: HttpCode = Http200,
    headers: HttpHeaders = newHttpHeaders(),
    body: string = ""
  ): Response {.gcsafe.} =
  ## create Response instance
  ## in general this will valued with Response instance with default value

  Response(
    httpCode: httpCode,
    headers: headers,
    body: body
  )
