import
  ../core/[
    httpContext,
    environment
  ],
  httpRanges
export
  httpContext,
  environment,
  httpRanges


proc replySendFile*(
    self: HttpContext,
    filePath: Path,
    httpHeaders: HttpHeaders = nil,
    env: Environment = environment.instance()
  ) {.gcsafe async.} = ## \
  ## reply with send file content

  # create static file route is static file
  let staticFile = newStaticFile(filePath)

  # file not accessible then reply with error 404
  if not staticFile.isAccessible:
    await self.replyJson(
        Http500,
        %newReplyMsg(
          httpCode = Http404,
          success = false,
          error = %*{"msg": "Resource not found!."}
        )
      )

    return

  # return static file as range
  # if range does not exist return ordinary response
  await self.replyRanges(staticFile, httpHeaders)
