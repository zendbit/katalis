##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## validation helper
## easy validation for Form, JsonNode and Table[string, string]
##


import
  options,
  tables,
  json,
  times

export
  options,
  tables,
  json,
  times


import
  ../core/form


import regex


type
  Field* = ref object of RootObj ## \
    ## Field item to validate

    name*: string ## \
    ## name of the field
    value*: string ## \
    ## value of the field
    isValid*: bool ## \
    ## flag if the field valid
    msg*: string ## \
    ## msg for field if the field success/failed on validation


  Validation*[
      T:Form |
      JsonNode |
      TableRef
    ] = ref object of RootObj ## \
    ## validation object type

    fields*: OrderedTable[string, Field] ## \
    ## not valid field list
    toCheck*: T ## \
    ## value to check
    field: Field ## \
    ## hold current field to check


proc newValidation*[
    T:Form |
    JsonNode |
    TableRef
  ](toCheck: T): Validation[T] {.gcsafe.} = ## \
  ## new validation

  Validation[T](
    toCheck: toCheck,
    fields: initOrderedTable[string, Field]()
  )


proc setMsg(
    self: Validation,
    failedMsg: string,
    okMsg: string
  ) {.gcsafe.} = ## \
  ## set message

  if self.field.isValid: self.field.msg = okMsg
  else: self.field.msg = failedMsg


proc getValue(self: Validation): string {.gcsafe.} = ## \
  ## get value from field

  when self.toCheck is Form:
    result =
      if self.toCheck.data.hasKey(self.field.name):
        self.toCheck.data.getOrDefault(self.field.name).strip
      elif self.toCheck.files.hasKey(self.field.name):
        self.field.name
      else: ""

  when self.toCheck is JsonNode:
    if not self.toCheck{self.field.name}.isNil:
      let val = self.toCheck{self.field.name}
      case val.kind
      of JInt:
        result = $val.getBiggestInt
      of JFloat:
        result = $val.getBiggestFloat
      of JBool:
        result = $val.getBiggestFloat
      else:
        result = $val

  when self.toCheck is TableRef[string, string]:
    result = self.toCheck.getOrDefault(self.field.name).strip


proc isRequired*(
    self: Validation,
    failedMsg: string = "Field is required",
    okMsg: string = ""
  ): Validation {.gcsafe discardable.} = ## \
  ## check field value empty or not

  ## if not valid from previous validation
  ## don't validate just return
  if not self.field.isValid: return self


  self.field.value = self.getValue

  if self.field.value == "":
      self.field.isValid = false

  self.setMsg(failedMsg, okMsg)
  self


proc isEmail*(
    self: Validation,
    failedMsg: string = "Email is not valid",
    okMsg: string = ""
  ): Validation {.gcsafe discardable.} = ## \
  ## check field value is email type

  ## if not valid from previous validation
  ## don't validate just return
  if not self.field.isValid: return self

  self.field.value = self.getValue

  if not self.field.value.contains("@") or
    self.field.value.split("@").len != 2:
    self.field.isValid = false

  self.setMsg(failedMsg, okMsg)
  self


proc minLength*(
    self: Validation,
    length: int,
    failedMsg: string = "Min length {length}",
    okMsg: string = ""
  ): Validation {.gcsafe discardable.} = ## \
  ## check field value minimum length

  ## if not valid from previous validation
  ## don't validate just return
  if not self.field.isValid: return self

  self.field.value = self.getValue

  if self.field.value.len < length:
    self.field.isValid = false

  self.setMsg(failedMsg.replace("{length}", $length), okMsg)
  self


proc maxLength*(
    self: Validation,
    length: int,
    failedMsg: string = "Max length {length}",
    okMsg: string = ""
  ): Validation {.gcsafe discardable.} = ## \
  ## check field value maximum length

  ## if not valid from previous validation
  ## don't validate just return
  if not self.field.isValid: return self

  self.field.value = self.getValue

  if self.field.value.len > length:
    self.field.isValid = false

  self.setMsg(failedMsg.replace("{length}", $length), okMsg)
  self


proc isNumber*(
    self: Validation,
    failedMsg: string = "Not number",
    okMsg: string = ""
  ): Validation {.gcsafe discardable.} = ## \
  ## check field value is number type

  ## if not valid from previous validation
  ## don't validate just return
  if not self.field.isValid: return self

  self.field.value = self.getValue

  try:
    discard self.field.value.parseFloat

  except CatchableError:
    self.field.isValid = false

  self.setMsg(failedMsg, okMsg)
  self


proc minValue*[T: int | float](
    self: Validation,
    value: T,
    failedMsg: string = "Min value {value}",
    okMsg: string = ""
  ): Validation {.gcsafe discardable.} = ## \
  ## check field minimum value

  ## if not valid from previous validation
  ## don't validate just return
  if not self.field.isValid: return self

  self.field.value = self.getValue
  when value is float:
    var parsedValue: float = 0

  else:
    var parsedValue: int = 0

  try:
    when value is float:
      parsedValue = self.field.value.parseFloat

    else:
      parsedValue = self.field.value.parseInt

    if parsedValue < value:
      self.field.isValid = false

  except CatchableError:
    self.field.isValid = false

  self.setMsg(failedMsg.replace("{value}", $value), okMsg)
  self


proc maxValue*[T: int | float](
    self: Validation,
    value: T,
    failedMsg: string = "Max value {value}",
    okMsg: string = ""
  ): Validation {.gcsafe discardable.} = ## \
  ## check field maximum value

  ## if not valid from previous validation
  ## don't validate just return
  if not self.field.isValid: return self

  self.field.value = self.getValue
  when value is float:
    var parsedValue: float = 0

  else:
    var parsedValue: int = 0

  try:
    when value is float:
      parsedValue = self.field.value.parseFloat

    else:
      parsedValue = self.field.value.parseInt

    if parsedValue > value:
      self.field.isValid = false

  except CatchableError:
    self.field.isValid = false

  self.setMsg(failedMsg.replace("{value}", $value), okMsg)
  self


proc isDateTime*(
    self: Validation,
    dateTimeFormat: string = "yyyy-MM-dd HH:mm:ss",
    tz: Timezone = local(),
    failedMsg: string = "Not date, datetime or time",
    okMsg: string = ""
  ): Validation {.gcsafe discardable.} = ## \
  ## check field value is datetime type

  ## if not valid from previous validation
  ## don't validate just return
  if not self.field.isValid: return self

  self.field.value = self.getValue
  try:
    discard times.parse(self.field.value, dateTimeFormat, tz)

  except CatchableError:
    self.field.isValid = false

  self.setMsg(failedMsg, okMsg)
  self


proc minDateTime*(
    self: Validation,
    dateTime: DateTime,
    dateTimeFormat: string = "yyyy-MM-dd HH:mm:ss",
    tz: Timezone = local(),
    failedMsg: string = "Min value {datetime}",
    okMsg: string = ""
  ): Validation {.gcsafe discardable.} = ## \
  ## check field value minimum datetime
  
  ## if not valid from previous validation
  ## don't validate just return
  if not self.field.isValid: return self

  self.field.value = self.getValue
  var parsedValue: DateTime
  try:
    parsedValue = times.parse(self.field.value, dateTimeFormat, tz)
    if parsedValue < dateTime:
      self.field.isValid = false

  except CatchableError:
    self.field.isValid = false

  self.setMsg(
    failedMsg.replace(
      "{datetime}", dateTime.format(dateTimeFormat, tz)
    ),
    okMsg
  )
  self


proc maxDateTime*(
    self: Validation,
    dateTime: DateTime,
    dateTimeFormat: string = "yyyy-MM-dd HH:mm:ss",
    tz: Timezone = local(),
    failedMsg: string = "Max value {datetime}",
    okMsg: string = ""
  ): Validation {.gcsafe discardable.} = ## \
  ## check field value maximum datetime

  ## if not valid from previous validation
  ## don't validate just return
  if not self.field.isValid: return self

  self.field.value = self.getValue
  var parsedValue: DateTime
  try:
    parsedValue = times.parse(self.field.value, dateTimeFormat, tz)
    if parsedValue > dateTime:
      self.field.isValid = false

  except CatchableError:
    self.field.isValid = false

  self.setMsg(
    failedMsg.replace(
      "{datetime}", dateTime.format(dateTimeFormat, tz)
    ),
    okMsg
  )
  self


proc inList*[T: seq[string] | seq[float] | seq[int]](
    self: Validation,
    values: seq[T],
    failedMsg: string = "Not in list",
    okMsg: string = ""
  ): Validation {.gcsafe discardable.} = ## \
  ## check field value is in list of values

  ## if not valid from previous validation
  ## don't validate just return
  if not self.field.isValid: return self

  self.field.value = self.getValue

  when T is seq[float]:
    var parsedValue: float = 0

  when T is seq[int]:
    var parsedValue: int = 0

  else:
    var parsedValue: string = ""
    parsedValue = self.field.value

  try:
    when T is seq[float]:
      var parsedValue: float = 0
      parsedValue = self.field.value.parseFloat

    when T is seq[int]:
      var parsedValue: int = 0
      parsedValue = self.field.value.parseInt

  except CatchableError:
    self.field.isValid = false

  self.field.isValid = parsedValue in values

  self.setMsg(failedMsg, okMsg)
  self


proc check*(
    self: Validation,
    cb: proc (v: string): bool,
    failedMsg: string = "Failed",
    okMsg: string = ""
  ): Validation {.gcsafe discardable.} = ## \\
  ## check field with callback procedure

  if not self.field.isValid: return self

  self.field.value = self.getValue
  self.field.isValid = self.field.value.cb

  self.setMsg(failedMsg, okMsg)
  self


proc matchWith*(
    self: Validation,
    regexExpr: string,
    failedMsg: string = "Not match with {regexExpr}",
    okMsg: string = ""
  ): Validation {.gcsafe discardable.} = ## \
  ## check field value is in list of values

  ## if not valid from previous validation
  ## don't validate just return
  if not self.field.isValid: return self

  self.field.value = self.getValue
  self.field.isValid = self.field.value.match(re2 regexExpr)

  self.setMsg(failedMsg.replace("{regexExpr}", regexExpr), okMsg)
  self


proc withField*(
    self: Validation,
    name: string
  ): Validation {.gcsafe.} = ## \
  ## add field to validate

  self.fields[name] = Field(name: name, isValid: true) ## \
  ## create new field then add field to fields table
  self.field = self.fields[name] ## \
  ## set current field pointer to field with last added
  self


proc allValid*(self: Validation): bool {.gcsafe.} = ## \
  ## return true all field valid

  for _, v in self.fields:
    if not v.isValid: return false

  true


proc validFields*(self: Validation): OrderedTable[string, Field] {.gcsafe.} = ## \
  ## get valid Fields

  result = initOrderedTable[string, Field]()
  for k, v in self.fields:
    if not v.isValid: continue
    result[k] = v


proc notValidFields*(self: Validation): OrderedTable[string, Field] {.gcsafe.} = ## \
  ## get not valid Fields

  result = initOrderedTable[string, Field]()
  for k, v in self.fields:
    if v.isValid: continue
    result[k] = v
