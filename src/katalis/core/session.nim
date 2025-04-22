##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## session management
##


## stdlib import
import
  std/[
    random,
    strutils,
    asyncfile,
    strtabs,
    paths,
    files
  ]

## nimble import
import checksums/sha1

import
  httpContext,
  environment,
  ../utils/crypt


const SessionId = "_SessId"

var sessionDir {.threadvar.}: Path


proc initSession*() {.gcsafe.} = ## \
  ## initialize session
  
  sessionDir = environment.instance().settings.storagesSessionDir


proc generateExpired(expired: int64): int64 {.gcsafe.} = ## \
  ## generate expired from current unixTime + expired in second
  
  now().utc.toTime.toUnix + expired


proc isSessionExists*(sessionToken: string): bool {.gcsafe.} = ## \
  ##
  ##  check if session already exists:
  ##
  ##  this will check the session token.
  ##
  result = (sessionDir/sessionToken.Path).fileExists


proc writeSession*(
    sessionToken: string,
    data: JsonNode
  ): Future[bool] {.gcsafe async.} = ## \
  ##
  ##  write session data:
  ##
  ##  the session data information in json format and will encrypted for security reason.
  ##
  let f = ($(sessionDir/sessionToken.Path)).openAsync(fmWrite)
  await f.write(xorEncodeDecode($data, sessionToken))
  f.close
  sessionToken.isSessionExists


proc createSessionToken*(expired: int64 = 2592000): Future[string] {.gcsafe async.} = ## \
  ##
  ##  create sossion token:
  ##
  ##  create string token session.
  ##
  let token = $secureHash(now().utc().format("YYYY-MM-dd HH:mm:ss:fffffffff") & $rand(1000000000)) & "-" & $expired.generateExpired()
  discard await token.writeSession(%*{})
  token


proc createSessionFromToken*(token: string): Future[bool] {.gcsafe async.} = ## \
  ##
  ##  create session from token:
  ##
  ##  this will generate session with given token and sessionAge in seconds.
  ##  will check if session conflict with other session or not
  ##  the session token will be used for accessing the session
  ##
  if not token.isSessionExists:
    result = await token.writeSession(%*{})


proc newSession*(data: JsonNode, expired: int64 = 2592000): Future[string] {.gcsafe async.} = ## \
  ##
  ##  create new session on server will return token access
  ##
  ##  token access is needed for retrieve, read, write and store the data
  ##  need to remember the token if using server side session
  ##  for cookie session token will manage by browser token will save on the cookie session
  ##
  let token = await createSessionToken(expired)
  if token.isSessionExists:
    discard await token.writeSession(data)

  token


proc readSession*(sessionToken: string): Future[JsonNode] {.gcsafe async.} = ## \
  ##
  ##  read session:
  ##
  ##  read session data with given token.
  ##
  if sessionToken.isSessionExists:
    let f = ($(sessionDir/sessionToken.Path)).openAsync
    result = (await f.readAll()).xorEncodeDecode(sessionToken).parseJson
    f.close


proc destroySession*(sessionToken: string) {.gcsafe.} = ## \
  ##
  ##  read session:
  ##
  ##  read session data with given token.
  ##
  if sessionToken.isSessionExists:
    (sessionDir/sessionToken.Path).removeFile


proc getCookieSession*(
    ctx: HttpContext,
    key: string
  ): Future[JsonNode] {.gcsafe async.} = ## \
  ##
  ##  get session:
  ##
  ##  get session value with given key from katalis HttpContext.
  ##
  let sessionData = await ctx.getCookie().getOrDefault(SessionId).readSession()
  if not sessionData.isNil and sessionData.hasKey("data"):
    result = sessionData{"data"}{key}


proc initCookieSession*(
    ctx: HttpContext,
    domain: string = "",
    path: string = "/",
    expires: string = "",
    secure: bool = false,
    sameSite: string = "Lax",
    httpOnly: bool = true
  ) {.gcsafe async.} = ## \
  ##
  ##  init cookie session:
  ##
  ##  add session data to katalis HttpContext. If key exists will overwrite existing data.
  ##

  try:
    var sessionData: JsonNode
    let cookie = ctx.getCookie
    var token = cookie.getOrDefault(SessionId)

    if token.isSessionExists:
      sessionData = await token.readSession

    elif token == "":
      ##
      ##  make sure token is already set in the client cookie
      ##  prevent ddos attack
      ##
      var expiresFormat: string
      var expiresVal: int64
      if expires == "":
        expiresFormat = ((now().utc + 7.days).toCookieDateFormat)

      expiresVal = expiresFormat.parseFromCookieDateFormat.toTime.toUnix

      token = await createSessionToken(expiresVal - now().utc.toTime.toUnix)
      ctx.setCookie({SessionId: token}.newStringTable, domain, path, expiresFormat, secure, sameSite, httpOnly)

    token = cookie.getOrDefault(SessionId)
    if token != "" and not token.isSessionExists:
      discard await token.createSessionFromToken()

    if token.isSessionExists:
      sessionData = await token.readSession
      if sessionData.isNil or sessionData{"data"}.isNil:
        sessionData = %*{"data": {}}

      discard await token.writeSession(sessionData)

  except CatchableError as ex:
    echo ex.msg


proc deleteCookieSession*(
    ctx: HttpContext,
    key: string
  ) {.gcsafe async.} = ## \
  ##
  ##  delete session:
  ##
  ##  delete session data with given key from katalis HttpContext.
  ##
  let token = ctx.getCookie().getOrDefault(SessionId)
  let sessionData = await token.readSession
  if not sessionData.isNil and sessionData.hasKey("data"):
    if sessionData{"data"}.hasKey(key):
      sessionData{"data"}.delete(key)
      discard await token.writeSession(sessionData)


proc addCookieSession*(
    ctx: HttpContext,
    key: string,
    val: JsonNode
  ) {.gcsafe async.} = ## \
  ##
  ##  add item to session:
  ##
  ##  delete session data with given key from katalis HttpContext.
  ##
  let token = ctx.getCookie().getOrDefault(SessionId)
  let sessionData = await token.readSession
  if not sessionData.isNil and sessionData.hasKey("data"):
    sessionData{"data"}{key} = val
    discard await token.writeSession(sessionData)


proc destroyCookieSession*(ctx: HttpContext) {.gcsafe.} = ## \
  ##
  ##  destory session:
  ##
  ##  will destroy all session key and data from katalis HttpContext.
  ##
  var cookie = ctx.getCookie
  let token = cookie.getOrDefault(SessionId)
  if token.isSessionExists:
    token.destroySession
    cookie.del(SessionId)

  if token != "":
    ctx.setCookie(cookie)
