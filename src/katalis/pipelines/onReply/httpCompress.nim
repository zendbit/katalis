##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## add pipeline on onreply
## check if client support compression then compress
##

import
  ../../core/routes,
  ../../macros/sugar,
  ../../plugins/httpCompress


@!App:
  @!OnReply:
    let contentType = @!Res.headers.contentType
    if contentType.toLower.contains("video/") or
      contentType.toLower.contains("audio/"): return
    await @!Context.gzipCompress(@!Env)
