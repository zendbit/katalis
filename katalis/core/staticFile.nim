##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## static file handling
##


import std/
[
  mimetypes,
  paths,
  asyncfile,
  asyncdispatch,
  httpcore,
  strformat,
  files
]


from os import FileInfo, getFileInfo


export
  mimetypes,
  paths,
  asyncfile,
  asyncdispatch,
  httpcore,
  strformat,
  FileInfo,
  files


import
  environment,
  multipart

export
  multipart


type
  StaticFile* = ref object of RootObj ## \
    ## static file object type

    info*: FileInfo ## \
    ## hold information about file
    isAccessible*: bool ## \
    ## flag to check if file is accessible
    msg*: string ## \
    ## hold message during action
    path*: Path ## \
    ## hold path of the file
    extension*: string ## \
    ## hold file extension
    mimeType*: string ## \
    ## hold mime type of file
    file*: AsyncFile ## \
    ## async file
    name*: string ## \
    ## file name


proc newStaticFile*(
    path: Path,
    safeMode: bool = false,
    env: Environment = environment.instance()
  ): StaticFile {.gcsafe.} =
  ## create new static file object
  ## using given path

  let staticFile = StaticFile(path: path.expandTilde)

  if staticFile.path.fileExists:
    try:
      staticFile.info = ($staticFile.path).getFileInfo()
      staticFile.isAccessible = true
      staticFile.msg = "Success"
      staticFile.name = $staticFile.path.extractFilename

      let fileParts = staticFile.path.splitFile()
      let mimetype = newMimetypes()
      staticFile.extension = fileParts.ext
      staticFile.mimeType = mimetype.
        getMimetype(fileParts.ext, default = "application/octet-stream")
    except Exception as e:
      staticFile.msg = e.msg
  else:
    staticFile.msg = &"{staticFile.path} doesn't exist."

  # check if safe mode
  # safe mode will check filesize
  # if filesize larger than maxBodySize
  # then set isAccessible to false
  # and msg to body is to big
  if safeMode:
    staticFile.isAccessible =
      staticFile.info.size <= env.settings.maxBodySize
    if not staticFile.isAccessible:
      staticFile.msg = "body is too big ({staticFile.info.size} bytes)."

  staticFile


proc open*(
    self: StaticFile,
    mode: FileMode = fmRead) {.gcsafe.} =
  ## open file

  if self.file.isNil:
    self.file = openAsync($self.path, mode)


proc close*(self: StaticFile) {.gcsafe.} =
  ## close file

  if not self.file.isNil:
    self.file.close
    self.file = nil


proc contents*(
    self: StaticFile,
    ranges: seq[tuple[start: BiggestInt, stop: BiggestInt]] = @[],
    env: Environment = environment.instance()
  ): Future[seq[string]] {.gcsafe async.} =
  ## read all contents of file

  self.open
  if ranges.len == 0:
    result.add(await self.file.readAll())
  else:
    for (start, stop) in ranges:
      var start = start
      var stop = stop
      let contentRangesLength = (stop - start) + 1
      if contentRangesLength < 0 or
        self.info.size <= start:
        start = 0

      self.file.setFilePos(start)

      if self.info.size > stop:
        result.add(await self.file.read(contentRangesLength))
      else:
        result.add(await self.file.read((self.info.size - start) + 1))
  self.close


proc contentsAsBytesRanges*(
    self: StaticFile,
    ranges: tuple[start: BiggestInt, stop: BiggestInt]
  ): Future[tuple[content: string, headers: HttpHeaders]] {.gcsafe async.} =
  ## get content as bytes ranges

  let contentRanges = (await self.contents(@[ranges]))[0]

  let headers = newHttpHeaders()
  headers.add("content-type", self.mimeType)
  headers.add(
    "content-range",
    &"bytes {ranges.start}-{ranges.stop}/{self.info.size}"
  )

  (contentRanges, headers)


proc contentsAsBytesRangesMultipart*(
    self: StaticFile,
    ranges: seq[tuple[start: BiggestInt, stop: BiggestInt]]
  ): Future[tuple[content: string, headers: HttpHeaders]] {.gcsafe async.} =
  ## get content as bytes ranges multipart

  let multipart = newMultipart()
  let contentsRanges = await self.contents(ranges)

  for i in 0..contentsRanges.high:
    # meta info for each part
    let metaData = {
        "content-type": self.mimeType,
        "content-range": &"bytes {ranges[i].start}-{ranges[i].stop}/{self.info.size}"
      }.newTable

    await multipart.add(metaData, contentsRanges[i])

  await multipart.done

  # header info for the response
  let headers = newHttpHeaders()
  headers.add(
    "content-type",
    &"multipart/byteranges; boundary={multipart.boundary}"
  )

  result = (
      await multipart.content(),
      headers
    )

