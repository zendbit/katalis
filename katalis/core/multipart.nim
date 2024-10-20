##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## handle multipart content
##

import std/
[
  oids,
  asyncdispatch,
  asyncfile,
  os,
  httpcore,
  strformat
]

export
  oids,
  asyncdispatch,
  asyncfile,
  os,
  httpcore,
  strformat


import
  constants,
  environment

export
  constants


type
  Multipart* = ref object of RootObj ## \
    ## multipart object

    contentType*: string ## \
    ## hold content-type
    contentLength*: BiggestInt ## \
    ## hold content-length
    boundary*: string ## \
    ## multipart data boundary
    contentBuffer*: AsyncFile ## \
    ## multipart data section


proc newMultipart*(
    boundary: string = $genOid(),
    env: Environment = environment.instance()
  ): Multipart = ## \
  ## create multipart object

  result = Multipart(
      boundary: boundary,
      contentBuffer: openAsync(
          env.settings.storagesDir.joinPath(boundary),
          fmReadWrite
        )
    )


proc add*(
    self: Multipart,
    content: string,
    headers: HttpHeaders = nil
  ) {.gcsafe async.} = ## \
  ## add content section into multipart
  
  # write boundary
  var data = &"--{self.boundary}{CRLF}"
  await self.contentBuffer.write(data)
  self.contentLength += data.len

  # add header section
  if not headers.isNil:
    for (k, v) in headers.pairs:
      data = &"{k}: {v}{CRLF}"
      await self.contentBuffer.write(data)
      self.contentLength += data.len

    data = &"{CRLF}"
    await self.contentBuffer.write(data)
    self.contentLength += data.len

  # add content sectioni
  data = &"{content}{CRLF}"
  await self.contentBuffer.write(data)
  self.contentLength += data.len


proc finalize*(self: Multipart) {.gcsafe async.} = ## \
  ## finalize multipart data section
  ## with ending boundary

  let data = &"--{self.boundary}--{CRLF}"
  await self.contentBuffer.write(data)
  self.contentLength += data.len


proc cleanup*(self: Multipart) {.gcsafe.} = ## \
  ## cleanup resource used by multipart

  self.contentBuffer.close()


proc getContents*(self: Multipart): Future[string] {.gcsafe async.} = ## \
  ## read multipart contents

  self.contentBuffer.setFilePos(0)
  await self.contentBuffer.readAll

