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


import zippy


import
  ../../core/routes,
  ../../macros/sugar,
  ../../core/environment


@!App:
  @!OnReply:
    # if client support gzip
    # and enableCompression enabled
    if "gzip" in
      @!Req.headers.getValues("accept-encoding") and
      @!Settings.enableCompression:

      @!Res.headers["content-encoding"] = "gzip"
      @!Res.body = compress(@!Res.body, BestSpeed, dfGzip)
