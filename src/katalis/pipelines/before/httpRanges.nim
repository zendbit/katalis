##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## parse ranges request
## Range: bytes=0-1000, 2000-3000
## see HTTP Ranges (accept-ranges)
##


import
  std/[
    options
  ]

import
  ../../core/routes,
  ../../macros/sugar,
  ../../core/environment,
  ../../plugins/httpRanges
export
  routes,
  sugar,
  environment,
  httpRanges


@!App:
  @!Before:
    await @!Context.parseHttpRangesFromHeader(@!Env)
