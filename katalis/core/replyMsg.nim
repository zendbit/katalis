##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## Reply message
##


import std/
[
  json,
  httpcore
]

export
  json,
  httpcore


import ../utils/json as utilsJson

export utilsJson


type
  ReplyMsg* = ref object of RootObj ## \
    ## RespMsg object type

    ## make response msg as standard response format
    httpCode*: HttpCode ## \
    ## http code
    success*: bool ## \
    ## indicate the response is succesfully http 200 (true)
    data*: JsonNode ## \
    ## data from the server
    error*: JsonNode ## \
    ## error from the server


proc newReplyMsg*(
    httpCode: HttpCode = Http200,
    success: bool = true,
    data: JsonNode = newJObject(),
    error: JsonNode = newJObject()
  ): ReplyMsg {.gcsafe.} =
  ## create RespMsg object

  ReplyMsg(
    httpCode: httpCode,
    success: success,
    data: data,
    error: error
  )

