import
  ../core/[
    httpContext,
    environment
  ]
export
  httpContext,
  environment

import
  strutils,
  strformat,
  streams
export
  strutils,
  strformat,
  streams


proc initHttpChunkedProperties*(self: HttpContext) {.gcsafe.} = ## \
  ## init http chunked properties

  if self.properties{"HttpChunked"}.isNil:
    self.properties["HttpChunked"] = %*{}


proc httpChunkedProperties*(self: HttpContext): JsonNode {.gcsafe.} = ## \
  ## http chunked properties

  self.initHttpChunkedProperties
  self.properties{"HttpChunked"}


proc composeHttpChunkedPayload*(
    self: HttpContext,
    env: Environment = environment.instance()
  ): string {.gcsafe.} =
  ## compose chunk payload
  ## chunked transfer encoding must follow this role
  ## for more details see about Transfer-Encoding: chunked

  result = self.response.body

  let bodyLength = self.response.body.len
  var chunkSize = env.settings.chunkSize

  if env.settings.enableChunkedTransfer and
    bodyLength >= chunkSize:

    self.response.headers["Transfer-Encoding"] = "chunked"

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
