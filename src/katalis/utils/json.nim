##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## expand std json
##


import
  std/[
    json as std_json,
    httpcore
  ]


proc `%`*(httpCode: HttpCode): JsonNode {.gcsafe.} =
  ## convert http code to int

  % httpCode.int
