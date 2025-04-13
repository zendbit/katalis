##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/nim_katalis
##

##
## Server utility for creating katalis instance
##


import
  core/katalis,
  macros/sugar,
  core/environment,
  core/routes,
  core/session,
  pipelines
export
  katalis,
  sugar,
  environment,
  routes,
  session,
  pipelines

import net
export net


var
  envInstance {.threadvar.}: Environment
  settings {.threadvar.}: Settings
  sslSettings {.threadvar.}: SslSettings
  katalisInstance {.threadvar.}: Katalis

envInstance = environment.instance()
settings = envInstance.settings
katalisInstance = katalis.instance()


proc initialize() {.gcsafe.} = ## \
  ## setup katalis before start serving

  if not settings.storagesBodyDir.dirExists:
    # check storage for body dir
    settings.storagesBodyDir.createDir

  if not settings.storagesUploadDir.dirExists:
    # check storage for upload dir
    settings.storagesUploadDir.createDir

  if not settings.storagesSessionDir.dirExists:
    # check storage for session dir
    settings.storagesSessionDir.createDir

  if not settings.storagesCacheDir.dirExists:
    # check storage for cache dir
    settings.storagesCacheDir.createDir

  # show traceging output
  @!Trace:
    echo ""
    echo "#== start"
    echo "Initialize Katalis"
    echo &"Bind address   : {settings.address}"
    echo &"Port           : {settings.port}"
    echo &"Debug          : {settings.enableTrace}"
    echo &"Reuse address  : {settings.enableReuseAddress}"
    echo &"Reuse port     : {settings.enableReusePort}"

    if isNil(sslSettings):
      echo &"Ssl            : {false}"

    else:
      echo &"Ssl            : {true}"
      echo &"Ssl Cert       : {sslSettings.certFile}"
      echo &"Ssl Key        : {sslSettings.keyFile}"
      echo &"Ssl Verify Peer: {sslSettings.enableVerify}"

    echo "#== end"
    echo ""

  ## init http katalis socket
  if katalisInstance.socketServer.isNil:
    katalisInstance.socketServer = newAsyncSocket()

  # init https katalis socket
  when WithSsl:
    if not settings.sslSettings.isNil and
      katalisInstance.sslSocketServer.isNil:

      var certFile = settings.sslSettings.certFile
      if not certFile.fileExists:
        certFile = paths.getCurrentDir()/certFile

      var keyFile = settings.sslSettings.keyFile
      if not keyFile.fileExists:
        keyFile = paths.getCurrentDir()/keyFile

      if certFile.fileExists and keyFile.fileExists:
        settings.sslSettings.certFile = certFile
        settings.sslSettings.keyFile = keyFile
        katalisInstance.sslSocketServer = newAsyncSocket()

      echo ""
      echo "#== Certificate Info"
      echo &"Certificate: {certFile}"
      echo &"Certificate found: {certFile.fileExists}"
      echo ""
      echo &"Key: {keyFile}"
      echo &"Key found: {keyFile.fileExists}"
      echo "#=="
      echo ""


proc clientListener(
    client: AsyncSocket,
    callback: proc (ctx: HttpContext) {.gcsafe async.}
  ) {.async gcsafe.} = ## \
  ## handle client listener
  ## will listen until the client socket closed

  let httpContext = newHttpContext(client = client)

  try:
    while not client.isClosed:
      # listen and wait for client request
      # if present then call the callback
      # callback(httpContext)
      await httpContext.callback

  except CatchableError as ex:
    @!Trace:
      echo ""
      echo "#== start"
      echo "Client connection closed, accept new session."
      echo ex.msg
      echo "#== end"
      echo ""


proc doServe(callback: proc (ctx: HttpContext) {.gcsafe async.}) {.async gcsafe.} = ## \
  ## start serve the katalis non secure

  if not katalisInstance.socketServer.isNil:
    katalisInstance.socketServer.setSockOpt(OptReuseAddr, settings.enableReuseAddress)
    katalisInstance.socketServer.setSockOpt(OptReusePort, settings.enableReusePort)
    katalisInstance.socketServer.setSockOpt(OptKeepAlive, settings.enableKeepAlive)
    katalisInstance.socketServer.bindAddr(settings.port, settings.address)
    katalisInstance.socketServer.listen

    let (host, port) = katalisInstance.socketServer.getLocalAddr
    # set siteUrl to shared envInstance
    let siteUrl = % &"http://{host}:{port}"
    envInstance.shared["siteUrl"] = siteUrl
    echo &"""Listening non secure (plain) on {siteUrl}"""

    while true:
      try:
        var client = await katalisInstance.socketServer.accept()
        asyncCheck clientListener(client, callback)

      except CatchableError as ex:
        # show trace
        @!Trace:
          echo ""
          echo "#== start"
          echo "Failed to serve."
          echo ex.msg
          echo "#== end"
          echo ""


when WithSsl:
  proc doServeSecure(callback: proc (ctx: HttpContext) {.gcsafe async.}) {.async gcsafe.} = ## \
    ## serve secure connection (https)

    if not katalisInstance.sslSocketServer.isNil:
      katalisInstance.sslSocketServer.setSockOpt(OptReuseAddr, settings.enableReuseAddress)
      katalisInstance.sslSocketServer.setSockOpt(OptReusePort, settings.enableReusePort)
      katalisInstance.sslSocketServer.setSockOpt(OptKeepAlive, settings.enableKeepAlive)
      katalisInstance.sslSocketServer.bindAddr(settings.sslSettings.port, settings.address)
      katalisInstance.sslSocketServer.listen

      let (host, port) = katalisInstance.sslSocketServer.getLocalAddr
      # set siteUrl to shared envInstance
      let siteUrl = % &"https://{host}:{port}"
      envInstance.shared["siteUrl"] = siteUrl
      echo &"""Listening secure on {siteUrl}"""

      var verifyMode = SslCVerifyMode.CVerifyNone
      if settings.sslSettings.enableVerify:
        verifyMode = SslCVerifyMode.CVerifyPeer

      var sslContext: SslContext

      if settings.sslSettings.enableUseEnv:
        # CVerifyPeerUseEnvVars mode
        sslContext = newContext(
            verifyMode = SslCVerifyMode.CVerifyPeerUseEnvVars,
            certFile = $settings.sslSettings.certFile,
            keyFile = $settings.sslSettings.keyFile,
            caDir = $settings.sslSettings.caDir,
            caFile = $settings.sslSettings.caFile
          )
      else:
        sslContext = newContext(
            verifyMode = verifyMode,
            certFile = $settings.sslSettings.certFile,
            keyFile = $settings.sslSettings.keyFile
          )

      while true:
        try:
          var client = await katalisInstance.sslSocketServer.accept()
          let (host, port) = katalisInstance.sslSocketServer.getLocalAddr()

          wrapConnectedSocket(sslContext, client,
            SslHandshakeType.handshakeAsServer, &"{host}:{port}")

          asyncCheck clientListener(client, callback)
        except CatchableError as ex:
          @!Trace:
            echo ""
            echo "#== start"
            echo "Failed to serve."
            echo ex.msg
            echo "#== end"
            echo ""


proc serve*() {.gcsafe.} = ## \
  ## serve the katalis
  ## will have secure and unsecure connection if SslSettings given

  # setup katalis
  initialize()

  proc callback(ctx: HttpContext) {.gcsafe async.} =
    try:
      await katalisInstance.r.doRoute(ctx, envInstance)

    except CatchableError as e:
      echo e.msg

  asyncCheck doServe(callback)

  when WithSsl:
    asyncCheck doServeSecure(callback)

  runForever()


proc emit*() {.gcsafe.} =
  ## run katalis
  serve()
