import
  ../core/[
    httpContext,
    environment
  ]
export
  httpContext,
  environment

import
  zippy
export
  zippy


proc isGzipCompressSupported*(
    self: HttpContext,
    env: Environment = environment.instance()
  ): bool {.gcsafe.} = ## \
  ## check if client support gzip compression

  # if client support gzip
  # and enableCompression enabled
  "gzip" in
    self.request.headers.getValues("accept-encoding") and
    env.settings.enableCompression


proc gzipCompress*(
    self: HttpContext,
    env: Environment = environment.instance()
  ) {.gcsafe async.} = ## \
  ## check if client support gzip compression

  # if client support gzip
  # and enableCompression enabled
  if self.isGzipCompressSupported:
    self.response.headers["content-encoding"] = "gzip"
    self.response.body = compress(self.response.body, BestSpeed, dfGzip)
