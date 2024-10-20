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


import std/
[
  streams,
  strutils
]


import
  ../../core/routes,
  ../../macros/sugar,
  ../../core/environment


proc composeChunkPayload(
    ctx: HttpContext,
    env: Environment = environment.instance()
  ): string {.gcsafe.} =
  ## compose chunk payload
  ## chunked transfer encoding must follow this role
  ## for more details see about Transfer-Encoding: chunked

  result = ctx.response.body

  let bodyLength = ctx.response.body.len
  var chunkSize = env.settings.chunkSize

  if env.settings.enableChunkedTransfer and
    bodyLength >= chunkSize:

    proc constructChunk(
        chunkSize: string,
        chunk: string
      ): string =

      result = chunkSize &
        $CRLF &
        chunk &
        $CRLF


    let numberOfChunks = (bodyLength / chunkSize).int
    var chunkSizeInHex = chunkSize.toHex
    let bodyStream = newStringStream(result)
    var bodyBuffer: string = ""

    for _ in 1..numberOfChunks:
      bodyBuffer &= constructChunk(
        chunkSizeInHex,
        bodyStream.readStr(chunkSize)
      )

    if bodyLength > chunkSize:
      chunkSize = bodyLength mod chunkSize
      bodyBuffer &= constructChunk(
        chunkSize.toHex,
        bodyStream.readStr(chunkSize)
      )

    bodyBuffer &= constructChunk("0", "")
    bodyStream.close()

    result = bodyBuffer


@!App:
  @!OnReply:
    if @!Req.httpMethod == HttpHead: return

    if not @!Settings.enableChunkedTransfer or
      @!Res.body.len > @!Env.settings.chunkSize:

      @!Res.body = @!Context.composeChunkPayload(@!Env)
      @!Res.headers["transfer-encoding"] = "chunked"

