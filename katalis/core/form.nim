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
  asyncdispatch
]

export
  tables,
  asyncdispatch


import
  staticFile,
  environment

export
  staticFile


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

