##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## Cleanup and write logs
##


import std/files

import
  ../../core/routes,
  ../../macros/sugar,
  ../../core/environment,
  ../../utils/debug
export
  routes,
  sugar,
  environment


@!App:
  @!Cleanup:
    await @!Settings.storagesLogDir.writeLog
    await clearLog()
