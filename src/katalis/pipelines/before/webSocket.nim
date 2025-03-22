##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## websocket middleware
## handle websocket upgrade
## from http
##


import
  ../../macros/sugar,
  ../../core/routes,
  ../../plugins/webSocket
export
  sugar,
  routes,
  webSocket


@!App:
  @!Before:
    await @!Context.parseWebSocketRequest(@!Env)
