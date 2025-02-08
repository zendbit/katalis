##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## add pipeline onreply
## as http protocol handler
## check if chunked Transfer-Encoding enabled or not
##



import
  ../../core/routes,
  ../../macros/sugar,
  ../../plugins/httpChunked


@!App:
  @!OnReply:
    if @!Req.httpMethod == HttpHead: return

    if @!Settings.enableChunkedTransfer and
      @!Res.body.len > @!Env.settings.chunkSize and
      @!Res.headers.getValues("ranges").len == 0:
      ## chunked cannot be used with ranges
      ## chunked conflict with Content-Length
      ## don't do chunked if response required Content-Length

      @!Res.body = @!Context.composeHttpChunkedPayload(@!Env)

