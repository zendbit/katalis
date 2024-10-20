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
  ../../core/environment


@!App:
  @!OnReply:
    # add server info into header
    var header = ""
    header &= &"{HttpVersion} {@!Res.httpCode}{CrLf}"
    header &= &"server: {ServerId} {ServerVersion}{CrLf}"

    # add server date info
    @!Res.headers["date"] = now().
      utc().
      format("ddd, dd MMM yyyy HH:mm:ss".
      initTimeFormat) & " GMT"

    # check if connection support keepalive
    if @!Context.isKeepAlive:
      @!Res.headers["connection"] = "keep-alive"

    else:
      @!Res.headers["connection"] = "close"
  
    if "chunked" in @!Res.headers.getValues("transfer-encoding"):
      @!Res.headers.del("content-length")

    else:
      @!Res.headers["content-length"] =  &"{@!Res.body.len}"

    # add additional headers into response header
    for k, v in @!Res.headers.pairs:
      header &= &"{k}: {v}{CrLf}"

    header &= CrLf

    if @!Req.httpMethod == HttpHead:
      @!Res.body = header
      
    else:
      @!Res.body = header & @!Res.body
