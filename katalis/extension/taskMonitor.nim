##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/nim_katalis
##

##
## task monitor for create task in the background
## with schedule, simple cron job
##


import
  os,
  std/locks,
  strutils,
  times,
  parseutils,
  strformat,
  std/typeinfo


type
  TaskScheduleType* = enum ## \
    ## task schedule type format

    Second
    Minute
    Hour
    Day
    DTime


  TaskToDo* = ref object of RootObj ## \
    ## Task to do item

    id*: string ## \
    ## task identifier, this will treat as unique
    toDo*: proc (p: Any) {.gcsafe.} ## \
    ## task todo callback to execute
    schedules*: seq[string] ## \
    ## taskSchedule is string format
    ## - if using datetime in UTC = 00 15 10 22 10#dtime -> second minute hour day month
    ## - if using offset in seconds = 3600#second
    ## - if using offset in minutes = 100#minute
    ## - if using offset hours = 10#hour
    ## - if using offset days = 3#day
    whenSchedules*: seq[int64] ## \
    ## this automatically set by system
    toDoParam: Any ## \
    ## task todo param


  TaskMonitor* = ref object of RootObj ## \
    ## Task monitor object

    toDoList*: seq[TaskToDo] ## \
    ## task list
    taskMonitorThread: Thread[TaskMonitor] ## \
    ## task monitor thread
    taskMonitorThreadLock: Lock ## \
    ## Task Monitor Lock


proc newTaskMonitor*: TaskMonitor = ## \
  ## create new TaskMonitor
  
  TaskMonitor()


proc findTaskToDo*(
  self: TaskMonitor,
  id: string
  ): int = ## \
  ## find task in toDoList
  ## return index of the task if found it

  for toDo in self.toDoList:
    if toDo.id == id:
      break

    result.inc

  if result == self.toDoList.len:
    result = -1


proc parseTaskSchedule*(taskSchedule: string): int64 = ## \
  ## parse schedule format
  ## 5#second, 10#minute etc to unixTime
  let taskScheduleFormat = taskSchedule.split("#")
  if taskScheduleFormat.len >= 2:
    let schedule = taskScheduleFormat[0].strip
    let scheduleType = taskScheduleFormat[1].strip.toLowerAscii
    var scheduleOffset: int64 = 0
    discard schedule.parseBiggestInt(scheduleOffset)
    let currentYear = now().utc.year

    case scheduleType
    of toLowerAscii $DTime:
      let dateTimeParts = schedule.split(".")
      if dateTimeParts.len >= 5:
        let second = datetimeParts[0].strip
        let minute = datetimeParts[1].strip
        let hour = datetimeParts[2].strip
        let day = datetimeParts[3].strip
        let month = datetimeParts[4].strip

        let scheduleTime = times.parse(
            $currentYear & "-" &
              (if month.len < 2: &"0{month}" else: $month) & "-" &
              (if day.len < 2: &"0{day}" else: $day) & "T" &
              (if hour.len < 2: &"0{hour}" else: $hour) & ":" &
              (if minute.len < 2: &"0{minute}" else: $minute) & ":" &
              (if second.len < 2: &"0{second}" else: $second),
            "yyyy-MM-dd'T'HH:mm:ss",
            utc()
          ).toTime.toUnix

        scheduleOffset = abs(scheduleTime - now().utc.toTime.toUnix)

    of toLowerAscii $Second:
      ## second use scheduleOffset
      discard
    of toLowerAscii $Minute:
      scheduleOffset = scheduleOffset * 60
    of toLowerAscii $Hour:
      scheduleOffset = scheduleOffset * 3600
    of toLowerAscii $Day:
      scheduleOffset = scheduleOffset * 3600 * 24

    result = scheduleOffset


proc addTaskSchedule*(
    self: TaskMonitor,
    id: string,
    taskSchedule: string
  ) {.gcsafe.} = ## \
  ## add schedule to task

  for toDo in self.toDoList:
    if toDo.id != id: continue
    if taskSchedule notin toDo.schedules:
      toDo.schedules.add(taskSchedule)
      toDo.whenSchedules.add(taskSchedule.parseTaskSchedule)


proc addTaskToDo*(
    self: TaskMonitor,
    id: string,
    toDo: proc (p: Any) {.gcsafe.},
    schedules: seq[string],
    toDoParam: Any
  ) {.gcsafe.} = ## \
  ## add new TaskToDo item to toDoList

  let toDoIndex = self.findTaskToDo(id)
  if toDoIndex < 0:
    let task = TaskToDo(
      id: id,
      toDo: toDo,
      schedules: schedules,
      toDoParam: toDoParam
    )

    for schedule in schedules:
      task.whenSchedules.add(schedule.parseTaskSchedule)

    self.toDoList.add(task)


proc doTask(tm: TaskMonitor) {.thread gcsafe.} = ## \
  ## do task callback
  ## will start on TaskToDo.emit

  while true:
    initLock(tm.taskMonitorThreadLock)
    for toDo in tm.toDoList:
      var index: uint = 0
      for schedule in toDo.schedules:
        if now().utc.toTime.toUnix >= toDo.whenSchedules[index]:
          toDo.toDo(toDo.toDoParam)
          toDo.whenSchedules[index] = now().utc.toTime.toUnix + schedule.parseTaskSchedule
        index = index + 1
    release(tm.taskMonitorThreadLock)

    ## check task for each 1 second
    sleep(1000)
  

proc emit*(self: TaskMonitor) = ## \
  ## emit and start task monitor
  initLock(self.taskMonitorThreadLock)
  createThread(self.taskMonitorThread, doTask, self)


proc isRunning*(self: TaskMonitor): bool = ## \
  ## check if task monitor is running

  self.taskMonitorThread.running
