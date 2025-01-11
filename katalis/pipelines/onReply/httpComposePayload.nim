##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## add pipeline on after route
## as http protocol handler
## handle http response
## basic header and body
##


import
  ../../core/routes,
  ../../macros/sugar,
  ../../extension/http


@!App:
  @!OnReply:
    await @!Context.composeHttpPayload(@!Env)
