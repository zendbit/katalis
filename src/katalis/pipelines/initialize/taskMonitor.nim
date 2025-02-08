##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## add middleware on before route
## task monitor thread
## will execute registered task depend on time given
##


import
  std/[
    dirs,
    typeinfo,
    times,
    paths,
    files
  ]
from std/os import getFileInfo

import
  ../../macros/sugar,
  ../../core/environment,
  ../../plugins/taskMonitor


var tm {.threadvar.}: TaskMonitor[Settings]
tm = newTaskMonitor[Settings]()


if not tm.isRunning:
  ## Storages Monitor
  ## will check storages especially for session, upload and body folder
  ## find unused file then delete it
  tm.addTaskToDo(
    "Storages Monitor",
    (proc (settings: Settings) {.gcsafe.} =
      let storagePaths = [
          settings.storagesUploadDir,
          settings.storagesBodyDir,
          settings.storagesSessionDir,
          settings.storagesCacheDir
        ]

      for storagesPath in storagePaths:
        if not storagesPath.dirExists: continue
        for dirItem in storagesPath.walkDirRec:
          let fileInfo = ($dirItem).getFileInfo
          if fileInfo.kind != pcFile: continue ## \
          ## only process file
          if (fileInfo.lastAccessTime.utc.toTime.toUnix + 604800) < now().utc.toTime.toUnix:
            ## if the file not accessed more than or equals one week
            ## then remove the file
            dirItem.removeFile
    ),
    @["24#hour"], ## check each 24 hour
    @!Settings
  )

  tm.emit()
