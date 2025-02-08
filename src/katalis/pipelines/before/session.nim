##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## session handler and initializer
##


import
  ../../core/routes,
  ../../macros/sugar,
  ../../core/environment,
  ../../core/session


@!App:
  @!Before:
    initSession()
