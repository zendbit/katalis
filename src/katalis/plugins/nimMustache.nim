##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## Mustache template system, using mustache template engine
## logicless template engine
## https://github.com/zendbit/moustachu
##


import
  std/[
    paths,
    files,
    tables
  ],
  strutils

import
  ../core/environment,
  ../macros/sugar,
  ../utils/debug

import mustache
export mustache, tables


type
  Mustache* = ref object of RootObj ## \
    ## view object

    data*: Context ## \
    ## moustache context
    templatesDir: Path ## \
    ## path to templatesDir


proc newMustache*(templatesDir: string = $(getCurrentDir() / Path("templates"))): Mustache = ## \
  ## create new view with partials dir for optional param
  ## default partialsDir is in templates dir

  Mustache(
    data: newContext(
      searchDirs = @[templatesDir]
    ),
    templatesDir: Path(templatesDir)
  )


proc render*(
    self: Mustache,
    templates: string
  ): string = ## \
  ## render moustache templates

  var templatesPath = self.templatesDir
  for p in templates.split("/"):
    templatesPath = templatesPath/p.Path

  templatesPath = ($templatesPath & ".mustache").Path

  try:
    if fileExists(templatesPath):
      result = readFile($templatesPath).render(self.data)
    else:
      result = templates.render(self.data)
  except Exception as e:
    result = "Failed to render!:\n\n" &
      templates & "\n\n" & e.msg

    @!Trace:
      echo ""
      echo "#=== start"
      echo "failed to render"
      echo templates
      echo e.msg
      echo "#=== end"
      echo ""

    waitFor result.putLog

