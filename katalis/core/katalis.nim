##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/nim_katalis
##

##
## katalis framework
##


import std/[
  nativesockets,
  strutils,
  os,
  base64,
  math,
  streams,
  asyncnet,
  asyncdispatch
]

## stdlib
export
  nativesockets,
  strutils,
  os,
  base64,
  math,
  streams,
  asyncnet,
  asyncdispatch


import routes


type
  # Katalis type
  Katalis* = ref object of RootObj
    ## socket server web katalis object type

    socketServer*: AsyncSocket ## \
    ## serve unsecure (http)
    sslSocketServer*: AsyncSocket ## \
    ## serve secure (https)
    r*: Routes ## \
    ## handle routes


var katalisInstance {.threadvar.}: Katalis ## \
## Katalist singleton


proc newKatalis(): Katalis {.gcsafe.} = ## \
  ## create katalis katalis with initial settings
  ## default value trace is off
  ## set trace to true if want to trace the data process

  result = Katalis(r: routes.instance()) ## \
  ## bind instance routes r() to r: Routes


# create instance on katalis
katalisInstance = newKatalis()


proc instance*(): Katalis {.gcsafe.} = ## \
  ## get instance of katalis

  katalisInstance
