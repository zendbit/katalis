##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## debug utility
##


import
  ../macros/sugar as macros_sugar
export
  macros_sugar

import std/[
  asyncfile,
  dirs,
  files,
  times,
  paths,
  asyncdispatch,
  strutils,
  strformat
]
export
  paths,
  asyncdispatch

var logs {.threadvar.}: seq[string]
logs = @[]

proc trace*(cb: proc () {.gcsafe.}) {.gcsafe.} =
  ## trace message

  when not CgiApp:
    if not isNil(cb): cb()
  else: discard


proc putLog*(log: string) {.async.} =
  logs.add(log)


proc clearLog*() {.async.} =
  logs = @[]


proc writeLog*(logDir: Path) {.async.} =
  if logs.len == 0: return
  if not logDir.dirExists:
    logDir.createDir

  if logDir.dirExists:
    try:
      let logFile = openAsync(
          $(logDir/(now().utc.format("dd-MMMM-yyyy") & ".log").Path),
          fmAppend
        )
      logs.insert(&"""=== {now().utc.format("dd-MMM-yyyy HH:mm:ss")} ===""", 0)
      await logFile.write(logs.join("\n") & "\n\n")
      logFile.close
    except CatchableError as err:
      echo err.msg
