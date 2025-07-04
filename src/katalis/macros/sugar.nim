##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## Macro definition for katalis
##


import
  std/[
    macros,
    tables,
    httpcore,
    xmlparser,
    json,
    unicode
  ]
export
  macros,
  tables,
  httpcore,
  xmlparser,
  json


import
  ../core/constants
export
  constants


type
  PipelineType = enum ## \
    ## Pipeline type

    Before
    After
    Cleanup
    OnReply


  RouteType = enum ## \
    ## route type
    WebSocket
    EndPoint


proc addRoute(
    httpMethod: NimNode,
    path: NimNode,
    stmtList: NimNode
  ): NimNode =
  ## add to route code generator

  nnkStmtList.newTree(
    nnkCall.newTree(
      nnkDotExpr.newTree(
        nnkCall.newTree(
          nnkDotExpr.newTree(
            ident("routes"),
            ident("instance")
          )
        ),
        ident("add")
      ),
      nnkPrefix.newTree(
        ident("@"),
        httpMethod # http method to generate
      ),
      path, # route path
      nnkLambda.newTree(
        newEmptyNode(),
        newEmptyNode(),
        newEmptyNode(),
        nnkFormalParams.newTree(
          newEmptyNode(),
          nnkIdentDefs.newTree(
            ident("ctx"),
            ident("HttpContext"),
            newEmptyNode()
          ),
          nnkIdentDefs.newTree(
            ident("env"),
            ident("Environment"),
            newEmptyNode()
          )
        ),
        nnkPragma.newTree(
          ident("gcsafe"),
          ident("async")
        ),
        newEmptyNode(),
        stmtList # stmtList from route code
      )
    )
  )


proc addOnreply(stmtList: NimNode): NimNode =
  ## add cleanup after process generator

  nnkStmtList.newTree(
    nnkCall.newTree(
      nnkDotExpr.newTree(
        nnkCall.newTree(
          nnkDotExpr.newTree(
            ident("routes"),
            ident("instance")
          )
        ),
        ident("addOnReply")
      ),
      nnkLambda.newTree(
        newEmptyNode(),
        newEmptyNode(),
        newEmptyNode(),
        nnkFormalParams.newTree(
          newEmptyNode(),
          nnkIdentDefs.newTree(
            ident("ctx"),
            ident("HttpContext"),
            newEmptyNode()
          ),
          nnkIdentDefs.newTree(
            ident("env"),
            ident("Environment"),
            newEmptyNode()
          )
        ),
        nnkPragma.newTree(
          ident("gcsafe"),
          ident("async")
        ),
        newEmptyNode(),
        stmtList # before code blockk
      )
    )
  )


proc addCleanup(stmtList: NimNode): NimNode =
  ## add cleanup after process generator

  nnkStmtList.newTree(
    nnkCall.newTree(
      nnkDotExpr.newTree(
        nnkCall.newTree(
          nnkDotExpr.newTree(
            ident("routes"),
            ident("instance")
          )
        ),
        ident("addCleanup")
      ),
      nnkLambda.newTree(
        newEmptyNode(),
        newEmptyNode(),
        newEmptyNode(),
        nnkFormalParams.newTree(
          newEmptyNode(),
          nnkIdentDefs.newTree(
            ident("ctx"),
            ident("HttpContext"),
            newEmptyNode()
          ),
          nnkIdentDefs.newTree(
            ident("env"),
            ident("Environment"),
            newEmptyNode()
          )
        ),
        nnkPragma.newTree(
          ident("gcsafe"),
          ident("async")
        ),
        newEmptyNode(),
        stmtList # before code blockk
      )
    )
  )


proc addBeforeRoute(stmtList: NimNode): NimNode =
  ## add before route generator

  nnkStmtList.newTree(
    nnkCall.newTree(
      nnkDotExpr.newTree(
        nnkCall.newTree(
          nnkDotExpr.newTree(
            ident("routes"),
            ident("instance")
          )
        ),
        ident("addBefore")
      ),
      nnkLambda.newTree(
        newEmptyNode(),
        newEmptyNode(),
        newEmptyNode(),
        nnkFormalParams.newTree(
          nnkBracketExpr.newTree(
            ident("Future"),
            ident("bool")
          ),
          nnkIdentDefs.newTree(
            ident("ctx"),
            ident("HttpContext"),
            newEmptyNode()
          ),
          nnkIdentDefs.newTree(
            ident("env"),
            ident("Environment"),
            newEmptyNode()
          )
        ),
        nnkPragma.newTree(
          ident("gcsafe"),
          ident("async")
        ),
        newEmptyNode(),
        stmtList # before code blockk
      )
    )
  )


proc addAfterRoute(stmtList: NimNode): NimNode =
  ## add before route generator

  nnkStmtList.newTree(
    nnkCall.newTree(
      nnkDotExpr.newTree(
        nnkCall.newTree(
          nnkDotExpr.newTree(
            ident("routes"),
            ident("instance")
          )
        ),
        ident("addAfter")
      ),
      nnkLambda.newTree(
        newEmptyNode(),
        newEmptyNode(),
        newEmptyNode(),
        nnkFormalParams.newTree(
          nnkBracketExpr.newTree(
            ident("Future"),
            ident("bool")
          ),
          nnkIdentDefs.newTree(
            ident("ctx"),
            ident("HttpContext"),
            newEmptyNode()
          ),
          nnkIdentDefs.newTree(
            ident("env"),
            ident("Environment"),
            newEmptyNode()
          )
        ),
        nnkPragma.newTree(
          ident("gcsafe"),
          ident("async")
        ),
        newEmptyNode(),
        stmtList # before code blockk
      )
    )
  )


proc buildRoutePath(
    parent: NimNode,
    child: NimNode
  ): NimNode =
  ## will merge to /auth/register

  nnkStmtList.newTree(
    nnkInfix.newTree(
      ident("&"),
      parent,
      child
    )
  )


proc app(body: NimNode): NimNode =
  ## app macro to make easy generate route code
  ## ex
  ## @!App:
  ##   @!Get "/login":
  ##     code
  ##   @![Post, Get] "/register":
  ##     code
  ##   ...
  
  var path: NimNode = newStrLitNode("")

  var stmtList = newStmtList()
  for childNode in body:
    # walk through body NimNode
    # analize the syntax form
    # if not nnkCommand then add to stmtList
    # and continue
    case childNode.kind
    of nnkPrefix:
      # get macro from katalis
      # with prefix @!
      let prefixNode = childNode[0]
      let prefixNodeName = childNode[1]

      case $prefixNode
      of "@!":
        case $prefixNodeName
        of $Before:
          # Berofe route action
          # @!Before
          stmtList.add(addBeforeRoute(stmtList = childNode[2]))

        of $After:
          # After route action
          # @!After
          stmtList.add(addAfterRoute(stmtList = childNode[2]))

        of $Cleanup:
          # Cleanup route action
          # @!Cleanup
          stmtList.add(addCleanup(stmtList = childNode[2]))

        of $OnReply:
          # OnReply route action
          # @!OnReply
          stmtList.add(addOnReply(stmtList = childNode[2]))

        else:
          stmtList.add(childNode)

    of nnkCommand:
      case childNode[0].kind
      of nnkPrefix:
        # prefix info
        # @!Get "param": stmt
        # @![Get, Post] "param": stmt
        # @!EndPoint "param"
        let prefixNode = childNode[0][0]
        let prefixNodeName = childNode[0][1]

        case $prefixNode
        of "@!":
          case prefixNodeName.kind
          of nnkIdent:
            # if non bracket macro
            # @!Get "/route_path"
            if HttpMethodTable.hasKey(($prefixNodeName).toUpper):
              # for HTTP METHOD REQUEST
              let httpMethod = nnkBracket.newTree(
                  ident(HttpMethodTable[($prefixNodeName).toUpper].codeStr)
                )

              stmtList.add(addRoute(
                  httpMethod,
                  buildRoutePath(path, childNode[1]), # path of route
                  childNode[2] # StmtList of action code,
                )
              )

            elif $prefixNodeName == $EndPoint:
              # set base endpoint for the route
              # @!EndPoint "/home"
              # will alter base prefix in the route with
              # "/home"
              path = childNode[1]

            elif $prefixNodeName == $WebSocket:
              # websocket action
              # @!WebSocket
              let httpMethod = nnkBracket.newTree(
                  newLit(HttpGet)
                )

              stmtList.add(addRoute(
                  httpMethod,
                  buildRoutePath(path, childNode[1]), # path of route
                  childNode[2] # StmtList of action code,
                )
              )

            else:
              stmtList.add(childNode)

          of nnkBracket:
            # if using bracket for multiple request
            # @![Get, Post] "/route/path"
            let httpMethod = nnkBracket.newTree()
            for hMethod in prefixNodeName:
              if not HttpMethodTable.hasKey(($hMethod).toUpper): continue
              httpMethod.add(ident(HttpMethodTable[($hMethod).toUpper].codeStr))

            stmtList.add(addRoute(
                httpMethod,
                buildRoutePath(path, childNode[1]), # path of route
                childNode[2] # StmtList of action code,
              )
            )

          else:
            stmtList.add(childNode)

        else:
          stmtList.add(childNode)

      else:
        stmtList.add(childNode)

    else:
      stmtList.add(childNode)

  stmtList


macro `@!`*(name: untyped): untyped =
  ## macro for get variable inside
  ## route callback
 
  case $name
  of "Context":
    ## only can call within route macro
    ## HttpContext instance
    ## call with @!Context
    ## or inside block code that have ctx: HttpContext param

    result = nnkStmtList.newTree(
        ident("ctx")
      )

  of "Env":
    ## only can call within route macro
    ## global Environment instance
    ## call with @!Env
    ## or inside block code that have Env: Environment param

    result = nnkStmtList.newTree(
        ident("env")
      )

  of "Req":
    ## only can call within route macro
    ## httpContext.request instance
    ## call with @!Req
    ## or inside block code that have ctx: HttpContext param

    result = nnkStmtList.newTree(
        nnkDotExpr.newTree(
          ident("ctx"),
          ident("request")
        )
      )

  of "Res":
    ## only can call within route macro
    ## httpContext.response instance
    ## call with @!Res
    ## or inside block code that have ctx: HttpContext param

    result = nnkStmtList.newTree(
        nnkDotExpr.newTree(
          ident("ctx"),
          ident("response")
        )
      )

  of "WebSocket":
    ## only can call within route macro
    ## httpContext.request instance
    ## call with @!WebSocket
    ## or inside block code that have ctx: HttpContext param

    result = nnkStmtList.newTree(
        nnkDotExpr.newTree(
          ident("ctx"),
          ident("webSocket")
        )
      )

  of "Client":
    ## only can call within route macro
    ## httpContext.client instance
    ## call with @!Client
    ## or inside block code that have ctx: HttpContext param

    result = nnkStmtList.newTree(
        nnkDotExpr.newTree(
          ident("ctx"),
          ident("client")
        )
      )

  of "Body":
    ## only can call within route macro
    ## httpContext.request.body - uri parameter
    ## call with @!Body
    ## return body non json, xml, form value
    ## or inside block code that have ctx: HttpContext param

    result = nnkStmtList.newTree(
        nnkDotExpr.newTree(
          nnkDotExpr.newTree(
            ident("ctx"),
            ident("request")
          ),
          ident("body")
        )
      )

  of "Segment":
    ## only can call within route macro
    ## httpContext.request.param.segment - uri parameter
    ## call with @!Segment
    ## or inside block code that have ctx: HttpContext param

    result = nnkStmtList.newTree(
        nnkDotExpr.newTree(
          nnkDotExpr.newTree(
            nnkDotExpr.newTree(
              ident("ctx"),
              ident("request")
            ),
            ident("param")
          ),
          ident("segment")
        )
      )

  of "Query":
    ## only can call within route macro
    ## httpContext.request.param.query - uri query string parameter
    ## call with @!Query
    ## or inside block code that have ctx: HttpContext param

    result = nnkStmtList.newTree(
        nnkDotExpr.newTree(
          nnkDotExpr.newTree(
            nnkDotExpr.newTree(
              ident("ctx"),
              ident("request")
            ),
            ident("param")
          ),
          ident("query")
        )
      )

  of "Json":
    ## only can call within route macro
    ## httpContext.request.param.json - json post param
    ## call with @!Json
    ## or inside block code that have ctx: HttpContext param

    result = nnkStmtList.newTree(
        nnkDotExpr.newTree(
          nnkDotExpr.newTree(
            nnkDotExpr.newTree(
              ident("ctx"),
              ident("request")
            ),
            ident("param")
          ),
          ident("json")
        )
      )

  of "Xml":
    ## only can call within route macro
    ## httpContext.request.param.xml - xml post param
    ## call with @!Xml
    ## or inside block code that have ctx: HttpContext param

    result = nnkStmtList.newTree(
        nnkDotExpr.newTree(
          nnkDotExpr.newTree(
            nnkDotExpr.newTree(
              ident("ctx"),
              ident("request")
            ),
            ident("param")
          ),
          ident("xml")
        )
      )

  of "Form":
    ## only can call within route macro
    ## httpContext.request.param.form - form post param
    ## call with @!Form
    ## or inside block code that have ctx: HttpContext param

    result = nnkStmtList.newTree(
        nnkDotExpr.newTree(
          nnkDotExpr.newTree(
            nnkDotExpr.newTree(
              ident("ctx"),
              ident("request")
            ),
            ident("param")
          ),
          ident("form")
        )
      )

  of "Emit":
    ## start katalis
    ## call with @!Emit
    ## only available when using:
    ##   import katalis

    result = nnkStmtList.newTree(
        nnkCall.newTree(
          ident("emit")
        )
      )

  of "Routes":
    ## routes singleton
    ## call with @!R
    ## only available when using:
    ##   import katalis

    result = nnkStmtList.newTree(
        nnkCall.newTree(
          nnkDotExpr.newTree(
            ident("routes"),
            ident("instance")
          )
        )
      )

  of "Katalis":
    ## Katalis singleton
    ## call with @!Katalis
    ## only available when using:
    ##   import katalis

    result = nnkStmtList.newTree(
        nnkCall.newTree(
          nnkDotExpr.newTree(
            ident("katalisApp"),
            ident("instance")
          )
        )
      )

  of "Environment":
    ## Environment singleton
    ## call with @!Environment
    ## only available when using:
    ##   import katalis|import Environment

    result = nnkStmtList.newTree(
        nnkCall.newTree(
          nnkDotExpr.newTree(
            ident("environment"),
            ident("instance")
          )
        )
      )

  of "Settings":
    ## Environment singleton
    ## call with @!Settings
    ## only available when using:
    ##   import katalis|import Environment

    result = nnkStmtList.newTree(
        nnkDotExpr.newTree(
          nnkCall.newTree(
            nnkDotExpr.newTree(
              ident("environment"),
              ident("instance")
            )
          ),
          ident("settings")
        )
      )

  of "SharedEnv":
    ## Environment singleton
    ## call with @!SharedEnv
    ## only available when using:
    ##   import katalis|import Environment

    result = nnkStmtList.newTree(
        nnkDotExpr.newTree(
          nnkCall.newTree(
            nnkDotExpr.newTree(
              ident("environment"),
              ident("instance")
            )
          ),
          ident("shared")
        )
      )

    ##
    ## for plugins
    ## start register here
    ##
  of "View":
    ## only available if procedure
    ## contains mustacheView pragma

    result = nnkStmtList.newTree(
        ident("mustacheView")
      )

  of "Check":
    ## only available if procedure
    ## contains validation pragma

    result = nnkStmtList.newTree(
        ident("checkValidation")
      )


macro `@!`*(
    name: untyped,
    body: untyped
  ): untyped =
  ## method nnkCall, nnkComment macro
  ## for @!, ex: @!App
  ##
  ## only available when using:
  ## import zc/katalis
  ## @!App:
  ##   @!Endpoint "/home"
  ##     @!Get "/home/login":
  ##       code
  ##

  case $name
  of "App":
    result = app(body)

  of "Trace":
    ## trace debug utility
    ## will check if environment.instance().settings.enableTrace
    ## if true will display trace message
    ## @!Trace:
    ##   code

    result = nnkStmtList.newTree(
        nnkIfStmt.newTree(
          nnkElifBranch.newTree(
            nnkDotExpr.newTree(
              nnkDotExpr.newTree(
                nnkCall.newTree(
                  nnkDotExpr.newTree(
                    ident("environment"),
                    ident("instance")
                  )
                ),
                ident("settings")
              ),
              ident("enableTrace")
            ),
            nnkStmtList.newTree(
              nnkCommand.newTree(
                ident("trace"),
                nnkLambda.newTree(
                  newEmptyNode(),
                  newEmptyNode(),
                  newEmptyNode(),
                  nnkFormalParams.newTree(
                    newEmptyNode()
                  ),
                  nnkPragma.newTree(
                    ident("gcsafe")
                  ),
                  newEmptyNode(),
                  body # trace block code
                )
              )
            )
          )
        )
      )
