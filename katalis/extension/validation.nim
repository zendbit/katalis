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
  tables

export
  options,
  tables


import
  ../core/form


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
      T:Form,
      JsonNode,
      TableRef
    ] = ref object of RootObj ## \
    ## validation object type

    validsField*: seq[Field] ## \
    ## valid field list
    notValidsField*: seq[Field] ## \
    ## not valid field list
    toCheck*: T ## \
    ## value to check


proc newValidation*[
    T:Form,
    JsonNode,
    TableRef
  ](toCheck: T): Validation {.gcsafe.} = ## \
  ## new validation

  Validation(toCheck: T)


proc isRequired*(
  self: Validation,
  name: string) {.gcsafe.} = ## \
  ## check field value empty or not

  discard


proc isEmail*(
  self: Validation,
  name: string) {.gcsafe.} = ## \
  ## check field value is email type

  discard


proc isPassword*(
  self: Validation,
  name: string) {.gcsafe.} = ## \
  ## check field value is password type

  discard


proc minLength*(
  self: Validation,
  name: string) {.gcsafe.} = ## \
  ## check field value minimum length

  discard


proc maxLength*(
  self: Validation,
  name: string) {.gcsafe.} = ## \
  ## check field value maximum length

  discard


proc isNumber*(
  self: Validation,
  name: string) {.gcsafe.} = ## \
  ## check field value is number type

  discard


proc minValue*(
  self: Validation,
  name: string) {.gcsafe.} = ## \
  ## check field minimum value

  discard


proc maxValue*(
  self: Validation,
  name: string) {.gcsafe.} = ## \
  ## check field maximum value

  discard


proc isDateTime*(
  self: Validation,
  name: string) {.gcsafe.} = ## \
  ## check field value is datetime type

  discard


proc minDateTime*(
  self: Validation,
  name: string) {.gcsafe.} = ## \
  ## check field value minimum datetime

  discard


proc maxDateTime*(
  self: Validation,
  name: string) {.gcsafe.} = ## \
  ## check field value maximum datetime

  discard


proc inList*(
  self: Validation,
  name: string) {.gcsafe.} = ## \
  ## check field value is in list of values

  discard


proc withField*(
    self: Validation,
    name: string,
    isRequired: Option[bool] = bool.none,
    minValue: Option[int] = int.none,
    maxValue: Option[int] = int.none,
    minLength: Option[int] = int.none,
    maxLength: Option[int] = int.none,
    isNumber: Option[bool] = bool.none,
    regex: Option[string] = string.none,
    isEmail: Option[bool] = bool.none,
    isPassword: Option[bool] = bool.none,
    errorMsg: Option[string] = string.none,
    successMsg: Option[string] = string.none,
    isDateTime: Option[bool] = bool.none,
    minDateTime: Option[string] = string.none,
    maxDateTime: Option[string] = string.none,
    dateTimeFormat: Option[string] = "yyyy-MM-dd HH:mm:ss".some,
    inList: Option[seq[string]] = seq[string].none
  ) {.gcsafe.} = ## \
  ## define field to check
  ## name of the field to check is required

  discard

