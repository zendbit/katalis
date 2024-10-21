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
  json

export
  options,
  tables,
  json


import
  ../core/form


type
  ValidationProperties* = ref object of RootObj ## \
    ## validation properties
    
    isRequired*: Option[bool]
    minValue*: Option[float]
    maxValue*: Option[float]
    minLength*: Option[int]
    maxLength*: Option[int]
    isNumber*: Option[bool]
    regexExpr*: Option[string]
    isEmail*: Option[bool]
    isPassword*: Option[bool]
    errorMsg*: Option[string]
    successMsg*: Option[string]
    isDateTime*: Option[bool]
    minDateTime*: Option[string]
    maxDateTime*: Option[string]
    dateTimeFormat*: Option[string]
    inList*: Option[seq[string]]
    

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

    validFields*: seq[Field] ## \
    ## valid field list
    notValidFields*: seq[Field] ## \
    ## not valid field list
    toCheck*: T ## \
    ## value to check


proc newValidation*[
    T:Form |
    JsonNode |
    TableRef
  ](toCheck: T): Validation[T] {.gcsafe.} = ## \
  ## new validation

  Validation[T](toCheck: toCheck)


proc isRequired(
    self: Validation,
    field: Field,
    properties: ValidationProperties
  ) {.gcsafe.} = ## \
  ## check field value empty or not

  if properties.errorMsg.isNone:
    properties.errorMsg = "Field is required.".some

  if properties.successMsg.isNone:
    properties.successMsg = "Valid.".some

  if self.toCheck is Form:
    if self.toCheck.data.getOrDefault(field.name) != "":
      field.value = self.toCheck.data[field.name]
      field.isValid = true

    else:
      field.isValid = false

  if field.isValid:
    field.msg = properties.successMsg.get

  else:
    field.msg = properties.errorMsg.get


proc isEmail(
    self: Validation,
    field: Field,
    properties: ValidationProperties
  ) {.gcsafe.} = ## \
  ## check field value is email type

  if properties.errorMsg.isNone:
    properties.errorMsg = "Email is not valid.".some

  if properties.successMsg.isNone:
    properties.successMsg = "Valid.".some
  
  if self.toCheck is Form:
    if self.toCheck.data.getOrDefault(field.name).contains("@"):
      field.value = self.toCheck.data[field.name]
      field.isValid = true
    
    else:
      field.isValid = false
  
  if field.isValid:
    field.msg = properties.successMsg.get

  else:
    field.msg = properties.errorMsg.get


proc isPassword(
    self: Validation,
    field: Field,
    properties: ValidationProperties
  ) {.gcsafe.} = ## \
  ## check field value is password type

  discard


proc minLength(
    self: Validation,
    field: Field,
    properties: ValidationProperties

  ) {.gcsafe.} = ## \
  ## check field value minimum length

  discard


proc maxLength(
    self: Validation,
    field: Field,
    properties: ValidationProperties
  ) {.gcsafe.} = ## \
  ## check field value maximum length

  discard


proc isNumber(
    self: Validation,
    field: Field,
    properties: ValidationProperties
  ) {.gcsafe.} = ## \
  ## check field value is number type

  discard


proc minValue(
    self: Validation,
    field: Field,
    properties: ValidationProperties
  ) {.gcsafe.} = ## \
  ## check field minimum value

  discard


proc maxValue(
    self: Validation,
    field: Field,
    properties: ValidationProperties
  ) {.gcsafe.} = ## \
  ## check field maximum value

  discard


proc isDateTime(
    self: Validation,
    field: Field,
    properties: ValidationProperties
  ) {.gcsafe.} = ## \
  ## check field value is datetime type

  discard


proc minDateTime(
    self: Validation,
    field: Field,
    properties: ValidationProperties
  ) {.gcsafe.} = ## \
  ## check field value minimum datetime

  discard


proc maxDateTime(
    self: Validation,
    field: Field,
    properties: ValidationProperties
  ) {.gcsafe.} = ## \
  ## check field value maximum datetime

  discard


proc inList(
    self: Validation,
    field: Field,
    properties: ValidationProperties
  ) {.gcsafe.} = ## \
  ## check field value is in list of values

  discard


proc regexExpr(
    self: Validation,
    field: Field,
    properties: ValidationProperties
  ) {.gcsafe.} = ## \
  ## check field value is in list of values

  discard


proc withField*(
    self: Validation,
    name: string,
    isRequired: Option[bool] = bool.none,
    minValue: Option[float] = float.none,
    maxValue: Option[float] = float.none,
    minLength: Option[int] = int.none,
    maxLength: Option[int] = int.none,
    isNumber: Option[bool] = bool.none,
    regexExpr: Option[string] = string.none,
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

  let field = Field(name: name)
  let properties = ValidationProperties(
      isRequired: isRequired,
      minValue: minValue,
      maxValue: maxValue,
      minLength: minLength,
      maxLength: maxLength,
      isNumber: isNumber,
      regexExpr: regexExpr,
      isEmail: isEmail,
      isPassword: isPassword,
      errorMsg: errorMsg,
      successMsg: successMsg,
      isDateTime: isDateTime,
      minDateTime: minDateTime,
      maxDateTime: maxDateTime,
      dateTimeFormat: dateTimeFormat,
      inList: inList
    )

  if isRequired.isSome: self.isRequired(field, properties)
  if isEmail.isSome: self.isEmail(field, properties)
  if isPassword.isSome: self.isPassword(field, properties)
  if minLength.isSome: self.minLength(field, properties)
  if maxLength.isSome: self.maxLength(field, properties)
  if isNumber.isSome: self.isNumber(field, properties)
  if minValue.isSome: self.minValue(field, properties)
  if maxValue.isSome: self.maxValue(field, properties)
  if isDateTime.isSome: self.isDateTime(field, properties)
  if minDateTime.isSome: self.minDateTime(field, properties)
  if maxDateTime.isSome: self.maxDateTime(field, properties)
  if inList.isSome: self.inList(field, properties)

