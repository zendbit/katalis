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


import
  ../../core/routes,
  ../../macros/sugar,
  ../../core/environment


@!App:
  @!Cleanup:
    if @!Req.body.fileExists:
      @!Req.body.removeFile

    if @!Req.param.form.files.len != 0:
      ## remove file after file uploaded
      ## uploaded file should be move after finished
      ## file uploaded before cleanup present
      for _, v in @!Req.param.form.files:
        if not v.isAccessible or not v.path.fileExists:
          continue

        v.path.removeFile

    ## clear http context
    @!Context.clear
