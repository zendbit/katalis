##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## View template system, using mustache template engine
## logicless template engine
## https://github.com/zendbit/moustachu
##


import
  std/paths,
  std/files

import
  ../core/environment

import moustachu
export moustachu


type
  View* = ref object of RootObj ## \
    ## view object

    context*: Context ## \
    ## moustache context
    templatesDir: Path ## \
    ## path to templatesDir


proc newView*(templatesDir: string = $(getCurrentDir() / Path("templates"))): View = ## \
  ## create new view with partials dir for optional param
  ## default partialsDir is in templates dir

  View(context: newContext(), templatesDir: Path(templatesDir))


proc render*(
    self: View,
    templates: string
  ): string = ## \
  ## render moustache templates

  let templatesPath = self.templatesDir / Path(templates & ".mustache")
  if fileExists(templatesPath):
    renderFile($templatesPath, self.context, $self.templatesDir)
  else:
    render(templates, self.context, $self.templatesDir)
