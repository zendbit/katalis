##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## http form
##


import std/
[
  tables,
  asyncdispatch,
  strformat,
  strutils,
  sequtils
]

export
  tables,
  asyncdispatch


import uri3


import
  staticFile,
  environment,
  multipart

export
  staticFile,
  multipart


type
  Form* = ref object of RootObj ## \
    ## form type object

    data*: TableRef[string, string] ## \
    ## hold form data non files
    files*: TableRef[string, seq[StaticFile]] ## \
    ## hold content disposition of files


proc newForm*(): Form {.gcsafe.} =
  ## create form object

  result = Form(
      data: newTable[string, string](),
      files: newTable[string, seq[StaticFile]]()
    )


proc addData*(
    self: Form,
    name: string,
    value: string
  ) {.gcsafe.} =
  ## add data name = value to form

  self.data[name] = value


proc addFile*(
    self: Form,
    name: string,
    file: StaticFile
  ) {.gcsafe.} =
  ## add file to form data

  if not self.files.contains(name):
    self.files[name] = @[file]
  else:
    self.files[name].add(file)


proc `[]=`*[T: string | StaticFile](
    self: Form,
    name: string,
    value: T
  ) {.gcsafe.} = ## \
  ## using [] to add new data

  when value is string:
    self.addData(name, value)
  else:
    self.addFile(name, value)


proc toUrlEncode*(self: Form): string {.gcsafe.} = ## \
  ## convert Form to urlencod

  var keyValPairs: seq[string] = @[]
  for k, v in self.data:
    keyValPairs.add(&"{k.encodeUri}={v.encodeUri}")

  keyValPairs.join("&")


proc toMultipart*(self: Form): Future[Multipart] {.gcsafe async.} = ## \
  ## convert Form to multipart

  result = newMultipart()
  for key, value in self.data:
    await result.add(
      {
        "Content-Disposition": &"form-data;name=\"{key}\""
      }.newTable,
      value
    )

  for key, value in self.files:
    let name = if value.len > 1: &"{key}[]" else: key
    for file in value:
      await result.add(
        {
          "Content-Disposition": &"form-data;name=\"{name}\";filename=\"{file.name}\"",
          "Content-Type": file.mimeType
        }.newTable,
        (await file.contents())[0]
      )

  await result.done
