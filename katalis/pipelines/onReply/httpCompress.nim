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
  ../../extension/httpCompress


@!App:
  @!OnReply:
    let contentType = @!Res.headers.getValues("Content-Type")
    if contentType.len != 0 and
      (contentType[0].toLower.contains("video/") or
        contentType[0].toLower.contains("audio/")): return
    await @!Context.gzipCompress(@!Env)
