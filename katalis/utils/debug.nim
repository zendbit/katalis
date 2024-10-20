##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## debug utility
##


import
  ../macros/sugar as macros_sugar

export
  macros_sugar


proc trace*(cb: proc () {.gcsafe.}) {.gcsafe.} =
  ## trace message

  if not isNil(cb): cb()
