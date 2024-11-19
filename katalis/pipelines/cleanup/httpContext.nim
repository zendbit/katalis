##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## Cleanup body request cache
##


import std/files

import
  ../../core/routes,
  ../../macros/sugar,
  ../../core/environment


@!App:
  @!Cleanup:
    if @!Req.body.Path.fileExists:
      @!Req.body.Path.removeFile

    if @!Req.param.form.files.len != 0:
      ## remove file after file uploaded
      ## uploaded file should be move after finished
      ## file uploaded before cleanup present
      for _, files in @!Req.param.form.files:
        for file in files:
          if not file.isAccessible or not file.path.fileExists:
            continue

          file.path.removeFile

    ## clear http context
    @!Context.clear
