##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## add middleware on before route
## as http protocol handler
##


import std/
[
  httpcore,
  nativesockets,
  math
]


import
  ../../core/routes,
  ../../macros/sugar,
  ../../extension/http


@!App:
  @!Before:
    await @!Context.parseHttpRequest(@!Env)
