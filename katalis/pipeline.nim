##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## Pipeline of the server
## the order of the include is important
## this make the server composable depend
## on the demand
##


# include initialize section
# this section will execute once on app start
include pipelines/initialize/
[
  taskMonitor
]


# include before route pipeline
# as chain sequence
include pipelines/before/
[
  http,
  webSocket,
  httpRanges,
  session
]


# include after route pipeline
# as chain sequence
include pipelines/after/
[
  httpStaticfile
]


# include onreply pipeline
# as chain sequence
include pipelines/onReply/
[
  httpCompress,
  httpChunked,
  httpComposePayload
]


# include cleanup pipeline
# as chain sequence
include pipelines/cleanup/
[
  httpContext
]
