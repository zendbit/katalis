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
    contentBufferUri*: string ## \
    ## content buffer uri file location


proc newMultipart*(
    boundary: string = $genOid(),
    env: Environment = environment.instance()
  ): Multipart = ## \
  ## create multipart object

  let contentBufferUri = env.settings.storagesCacheDir.joinPath(boundary)
  result = Multipart(
      boundary: boundary,
      contentType: "multipart/form-data",
      contentBufferUri: contentBufferUri,
      contentBuffer: openAsync(
          contentBufferUri,
          fmReadWrite
        )
    )


proc add*(
    self: Multipart,
    metaData: TableRef[string, string],
    content: string
  ) {.gcsafe async.} = ## \
  ## add content section into multipart
  
  # write boundary
  var data = &"--{self.boundary}{CRLF}"
  # add meta header section
  for key, value in metaData:
    data &= &"""{key}: {value}{CRLF}"""

  ## CRLF after ending of metadata info
  data &= CRLF

  # add content sectioni
  data &= &"{content}{CRLF}"
  await self.contentBuffer.write(data)
  self.contentLength += data.len


proc done*(self: Multipart) {.gcsafe async.} = ## \
  ## finalize multipart data section
  ## with ending boundary

  let data = &"--{self.boundary}--{CRLF}"
  await self.contentBuffer.write(data)
  self.contentLength += data.len
  self.contentBuffer.close()


proc content*(self: Multipart): Future[string] {.gcsafe async.} = ## \
  ## read multipart contents

  let openBuffer = openAsync(self.contentBufferUri, fmRead)
  result = await openBuffer.readAll
  openBuffer.close

