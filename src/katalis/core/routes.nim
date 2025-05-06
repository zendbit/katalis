##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## handle routing and matching request
## manipulating site route
##


from std/asynchttpserver import HttpMethod
import
  std/[
    asyncdispatch,
    tables,
    strformat,
    strutils,
    json,
    paths,
    files,
    sequtils
  ]
## stdlib

export
  tables,
  strutils,
  asyncdispatch,
  json,
  strformat,
  paths,
  files,
  sequtils


import
  uri3,
  regex
## nimble

export
  uri3,
  regex


import
  httpContext,
  environment,
  staticFile,
  replyMsg,
  ../utils/json as utilsJson

export
  httpContext,
  staticFile,
  replyMsg,
  utilsJson


type
  Route* = ref object of RootObj ## \
    ## Route context object type

    httpMethod*: seq[HttpMethod] ## \
    ## HTTP method
    path*: string ## \
    ## path to route, hold path after valid domain section
    thenDo*: proc (
        ctx: HttpContext,
        env: Environment = environment.instance()
      ) {.gcsafe async.} ## \
    ## callback on route action
    segments*: seq[string] ## \
    ## hold segment path as sequence
    isStatic*: bool ## \
    ## indicate static file or not


  Routes* = ref object of RootObj ## \
    ## Routes object for routing

    routeList: seq[Route] ## \
    ## hold route list
    before: seq[
        proc (
            ctx: HttpContext,
            env: Environment = environment.instance()
          ): Future[bool] {.gcsafe async.}
      ] ## \
    after: seq[
        proc (
            ctx: HttpContext,
            env: Environment = environment.instance()
          ): Future[bool] {.gcsafe async.}
      ] ## \
    ## hold before route action list
    onReply: seq[
        proc (
            ctx: HttpContext,
            env: Environment = environment.instance()
          ) {.gcsafe async.}
      ] ## \
    ## hold onReply action list
    cleanup: seq[
        proc (
            ctx: HttpContext,
            env: Environment = environment.instance()
          ) {.gcsafe async.}
      ] ## \
    ## hold after all process reply


var routesInstance {.threadvar.}: Routes ## \
## routes singleton


proc newRoutes*(): Routes {.gcsafe.} =
  ## create new route object
  ## Routes(routeTable: newTable[string, Route]())
  Routes()


routesInstance = newRoutes() ## \
## initialize root instance


proc instance*(): Routes {.gcsafe.} =
  ## return route instance

  routesInstance


proc `==`*(first: Route, second: Route): bool {.gcsafe.} =
  ## compare two route

  first.path == second.path and
    first.httpMethod == second.httpMethod


proc normalizePath(path: string): string {.gcsafe.} = ## \
  ## normalize path
  ## if path end with /
  ## then remove it
  var path = path
  if path.len > 1 and path[^1] == '/':
    path = path[0..(path.len - 2)]

  path


proc add*(
    self: Routes,
    httpMethod: seq[HttpMethod],
    path: string,
    thenDo: proc (
        ctx: HttpContext,
        env: Environment = environment.instance()
      ) {.gcsafe async.}
  ) {.gcsafe.} =
  ## add route to route list
  ## route(
  ##     HttpGet,
  ##     "/register",
  ##     proc (ctx: HttpContext) {.gcsafe async.} =
  ##       ctx.response.httpCode = Http200
  ##       await ctx.resp
  ##   )

  let path = path.normalizePath
  self.routeList.add(
    Route(
      httpMethod: httpMethod,
      path: path,
      thenDo: thenDo,
      segments: parseUri3(path).getPathSegments()
    )
  )


proc routeList*(self: Routes): seq[Route] {.gcsafe.} =
  ## return route context list

  self.routeList


proc findRoute*(
    self: Routes,
    httpMethod: HttpMethod,
    path: string
  ): Route {.gcsafe.} = ## \
  ## find route

  let routeList = self.routeList.filter(
      proc (r: Route): bool =
        httpMethod in r.httpMethod and
          r.path == path
    )

  if routeList.len != 0:
    result = routeList[0]


proc findRoute*(
    self: Routes,
    path: string
  ): Route {.gcsafe.} = ## \
  ## find route

  let routeList = self.routeList.filter(
      proc (r: Route): bool =
        r.path == path
    )

  if routeList.len != 0:
    result = routeList[0]


proc addBefore*(
    self: Routes,
    thenDo: proc (
        ctx: HttpContext,
        env: Environment = environment.instance()
      ): Future[bool] {.gcsafe async.}
  ) {.gcsafe.} =
  ## add before route action

  self.before.add(thenDo)


proc addAfter*(
    self: Routes,
    thenDo: proc (
        ctx: HttpContext,
        env: Environment = environment.instance()
      ): Future[bool] {.gcsafe async.}
  ) {.gcsafe.} =
  ## add after route action

  self.after.add(thenDo)


proc addCleanup*(
    self: Routes,
    thenDo: proc (
        ctx: HttpContext,
        env: Environment = environment.instance()
      ) {.gcsafe async.}
  ) {.gcsafe.} =
  ## add cleanup route action

  self.cleanup.add(thenDo)


proc addOnReply*(
    self: Routes,
    thenDo: proc (
        ctx: HttpContext,
        env: Environment = environment.instance()
      ) {.gcsafe async.}
  ) {.gcsafe.} =
  ## add cleanup route action

  self.onReply.add(thenDo)


proc doBeforeRoute*(
    self: Routes,
    ctx: HttpContext,
    env: Environment = environment.instance()
  ): Future[bool] {.gcsafe async.} =
  ## before route handler

  for thenDo in self.before:
    # check if some of the action return true
    # then skip all other action
    if await thenDo(ctx, env):
      result = true
      break


proc doAfterRoute*(
    self: Routes,
    ctx: HttpContext,
    env: Environment = environment.instance()
  ): Future[bool] {.gcsafe async.} =
  ## after route handler

  for thenDo in self.after:
    # check if some of the action return true
    # then skip all other action
    if await thenDo(ctx, env):
      result = true
      break


proc doCleanup*(
    self: Routes,
    ctx: HttpContext,
    env: Environment = environment.instance()
  ) {.gcsafe async.} =
  ## cleanup after all action
  ## sent to client

  for thenDo in self.cleanup:
    await thenDo(ctx, env)


proc doOnreply*(
    self: Routes,
    ctx: HttpContext,
    env: Environment = environment.instance()
  ) {.gcsafe async.} =
  ## cleanup after all action
  ## sent to client

  for thenDo in self.onReply:
    await thenDo(ctx, env)


proc matchRoute(
    routes: Routes,
    requestMethod: HttpMethod,
    requestPath: string
  ): tuple[route: Route, param: TableRef[string, string]] =
  ## get segment param from request path
  ## match between requestPath with routePath
  ## then retrieve the segment params

  let requestPath = requestPath.normalizePath
  var param = newTable[string, string]()
  var regexMatch: RegexMatch2
  # fo non regex segment /:id/helo/:year/...
  var captureSegmentIds, captureSegmentValues: seq[string]
  # for segment param using :context
  let segmentMatchPatternIds = "/:([0-9A-Za-z\\-_]+)"
  # for regex matching :re<id:([0-9]+)_[a-zA-Z0-9]+$>
  let segmentRegexMatchPattern = "/re<([^\\/]+)>"
  let segmentRegexMatchPatternIds = ":([0-9a-zA-Z]+)\\("
  # get params segments name
  # ex extract from /profile/:id/details/:address
  for r in routes.routeList:
    # if http method different just skip
    if requestMethod notin r.httpMethod: continue

    # find all :context
    # clean unused for macthing
    # re<...>
    var routePathMatchPattern: string = (r.path & "$").
      replace("/re<", "/").
      replace(">/", "/").
      replace(">", "")

    if requestPath.match(re2 routePathMatchPattern):
      # if match in the first place
      # without match any variable name
      # will match with this kind of route path
      # GET "/regex-test/re<[0-9]+_[a-z]+_[0-9]+>/ok":
      result = (r, param)
      break

    #for segmentRegex in rKey.findAll(re2 segmentRegexMatchPattern):
    for segmentRegex in r.path.findAll(re2 segmentRegexMatchPattern):
      # match with multiple variable name
      # will match with this kind of route path
      # GET "/regex-test/re<:id([0-9]+)_:name([a-zA-Z0-9]+)>/ok":
      let currentSegmentRegex = r.path[segmentRegex.group(0)]
      for segmentRegexId in
        currentSegmentRegex.
        findAll(re2 segmentRegexMatchPatternIds):

        captureSegmentIds.add(
          currentSegmentRegex[segmentRegexId.group(0)]
        )

        # replace match :context for matching pattern
        routePathMatchPattern = routePathMatchpattern.
          replace(
            &":{captureSegmentIds[captureSegmentIds.high]}",
            ""
          )

    # if capture regex segment not found
    # then do regular :some_match /:id/hello/...
    # will match with this kind of route path
    # GET "/regex-test/:id/test":
    if captureSegmentIds.len == 0:
      for segmentId in r.path.findAll(re2 segmentMatchPatternIds):
        # collect segmentId from route path pattern (:context)
        # captureSegmentIds.add(rKey[segmentId.group(0)])
        captureSegmentIds.add(r.path[segmentId.group(0)])
        # generate routePathMatcPattern regex match again requestPath
        # with given captureSegmentIds
        routePathMatchPattern = routePathMatchPattern.
          replace(
            &"/:{captureSegmentIds[captureSegmentIds.high]}",
            segmentMatchPatternIds.replace("/:", "/")
          )

    # match requestPath with generated routePathMatchPattern
    if requestPath.match(re2 routePathMatchPattern, regexMatch):
      for segmentIdIndex in 0..captureSegmentIds.high:
        captureSegmentValues.add(requestPath[regexMatch.group(segmentIdIndex)])

      # if pattern requestPath match with routePathMatchPattern
      # then set result return value to selected route by rKey
      # then break
      if captureSegmentIds.len == captureSegmentValues.len and
        captureSegmentIds.len != 0:
        # set value paramSegment on request httpContext
        for segmentIdIndex in 0..captureSegmentIds.high:
          param[captureSegmentIds[segmentIdIndex]] = captureSegmentValues[segmentIdIndex]
          result = (r, param)

      # break if route regex match with given pattern
      break

    captureSegmentIds = @[]
    captureSegmentValues = @[]


proc matchRoute(
    self: Routes,
    ctx: HttpContext,
    env: Environment = environment.instance()
  ): Route {.gcsafe.} =

  var currentRoute: Route
  let request = ctx.request
  let settings = env.settings
  #let routes = self.routeTable
  #let routes = self.routeList
  when not CgiApp:
    var requestStaticPath = request.uri.getPathSegments().
      join($DirSep).decodeUri()
    var requestPath = request.uri.getPath().decodeUri()
  else:
    var requestStaticPath = request.uri.getQuery("uri").
      replace("/", $DirSep).
      decodeUri()
    var requestPath = request.uri.getQuery("uri").decodeUri()

  # static route found
  # if found then set reqest isStatic to true
  if settings.enableServeStatic and
    (settings.staticDir/requestStaticPath.Path).fileExists and
    request.httpMethod in [HttpGet, HttpOptions, HttpHead]:
    request.isStaticfile = true

  # if request path match with @!routes return matched route:
  if not request.isStaticfile:
    #if routes.hasKey(requestPath) and
    #  request.httpMethod in routes[requestPath].httpMethod:
    #  currentRoute = routes[requestPath]
    currentRoute = self.findRoute(request.httpMethod, requestPath)

    # if not match any, then try to match with
    # param segment variable
    # /x/:context/y/:context/...
    if currentRoute.isNil:
      # find all :context
      # retrieve segment params
      let paramSegment = self.matchRoute(request.httpMethod, requestPath)
      if not paramSegment.route.isNil:
        request.param.segment = paramSegment.param
        currentRoute = paramSegment.route

  # if result not nil then collect some parameter
  # like query string
  for (k, v) in request.uri.getQueries():
    request.param.query[k] = v

  currentRoute


proc doRoute*(
    self: Routes,
    ctx: HttpContext,
    env: Environment = environment.instance()
  ) {.gcsafe async.} =
  ## start routing from here
  ## see pipelines/http_request_routes

  try:
    # httpContext.onReply callback
    ctx.onReply = proc (
        ctx: HttpContext,
        env: Environment = environment.instance()
      ) {.gcsafe async.} =

      await self.doOnreply(ctx, env)

    # call before route action
    if not await self.doBeforeRoute(ctx, env):
      # check if dynamic route
      # found
      let route = self.matchRoute(ctx, env)
      if not route.isNil or ctx.request.isStaticfile:
        if not await self.doAfterRoute(ctx, env):
          if not route.isNil:
            await route.thenDo(ctx, env)

      else:
        await ctx.replyJson(
            Http404,
            %newReplyMsg(
              httpCode = Http404,
              success = false,
              error = %*{"msg": "Resource not found!."}
            )
          )

  except CatchableError as ex:
    await ctx.replyJson(
        Http500,
        %newReplyMsg(
          httpCode = Http500,
          success = false,
          error = %*{"msg": &"{ex.msg}"}
        )
      )

  await ctx.reply(env)

  # do cleanup process
  # after all action
  await self.doCleanup(ctx, env)
