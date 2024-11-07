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


include pipelines

import
  core/katalis,
  macros/sugar,
  core/environment,
  core/routes,
  core/session

export
  katalis,
  sugar,
  environment,
  routes,
  session


var
  envInstance {.threadvar.}: Environment
  settings {.threadvar.}: Settings
  sslSettings {.threadvar.}: SslSettings
  katalisInstance {.threadvar.}: Katalis

envInstance = environment.instance()
settings = envInstance.settings
sslSettings = settings.sslSettings
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
  if isNil(katalisInstance.socketServer):
    katalisInstance.socketServer = newAsyncSocket()

  # init https katalis socket
  when WithSsl:
    if not sslSettings.isNil and
      katalisInstance.sslSocketServer.isNil:

      var certFile = sslSettings.certFile
      if not certFile.fileExists:
        certFile = getCurrentDir().joinPath(certFile)

      var keyFile = sslSettings.keyFile
      if not keyFile.fileExists:
        keyFile = getCurrentDir().joinPath(keyFile)

      if certFile.fileExists and keyFile.fileExists:
        sslSettings.certFile = certFile
        sslSettings.keyFile = keyFile
        katalisInstance.sslSocketServer = newAsyncSocket()

      else:
        echo "--"
        echo &"Certificate: {certFile}"
        echo &"Certificate found: {certFile.fileExists}"
        echo "--"
        echo &"Key: {keyFile}"
        echo &"Key found: {keyFile.fileExists}"
        echo "--"


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

  except Exception as ex:
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
    katalisInstance.socketServer.setSockOpt(OptBroadcast, settings.enableBroadcast)
    katalisInstance.socketServer.setSockOpt(OptDontRoute, settings.enableDontRoute)
    katalisInstance.socketServer.setSockOpt(OptOOBInline, settings.enableOOBInline)
    katalisInstance.socketServer.bindAddr(settings.port, settings.address)
    katalisInstance.socketServer.listen

    let (host, port) = katalisInstance.socketServer.getLocalAddr
    # set siteUrl to shared envInstance
    envInstance.shared["siteUrl"] = &"http://{host}:{port}"
    echo &"""Listening non secure (plain) on {envInstance.shared["siteUrl"]}"""

    while true:
      try:
        var client = await katalisInstance.socketServer.accept()
        asyncCheck clientListener(client, callback)

      except Exception as ex:
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
      katalisInstance.sslSocketServer.setSockOpt(OptBroadcast, settings.enableBroadcast)
      katalisInstance.sslSocketServer.setSockOpt(OptDontRoute, settings.enableDontRoute)
      katalisInstance.sslSocketServer.setSockOpt(OptOOBInline, settings.enableOOBInline)
      katalisInstance.sslSocketServer.bindAddr(settings.sslSettings.port, settings.address)
      katalisInstance.sslSocketServer.listen

      let (host, port) = katalisInstance.sslSocketServer.getLocalAddr
      # set siteUrl to shared envInstance
      envInstance.shared["siteUrl"] = &"http://{host}:{port}"
      echo &"Listening secure on {envInstance.shared["siteUrl"]}"

      var verifyMode = SslCVerifyMode.CVerifyNone
      if sslSettings.verify:
        verifyMode = SslCVerifyMode.CVerifyPeer

      var sslContext: SslContext

      if sslSettings.useEnv:
        # CVerifyPeerUseEnvVars mode
        sslContext = newContext(
            verifyMode = SslCVerifyMode.CVerifyPeerUseEnvVars,
            certFile = sslSettings.certFile,
            keyFile = sslSettings.keyFile,
            caDir = sslSettings.caDir,
            caFile = sslSettings.caFile
          )
      else:
        sslContext = newContext(
            verifyMode = verifyMode,
            certFile = sslSettings.certFile,
            keyFile = sslSettings.keyFile
          )


      while true:
        try:
          var client = await katalisInstance.sslSocketServer.accept()
          let (host, port) = katalisInstance.sslSocketServer.getLocalAddr()

          wrapConnectedSocket(sslContext, client,
            SslHandshakeType.handshakeAsServer, &"{host}:{port}")

          asyncCheck clientListener(client, callback)
        except Exception as ex:
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

    except Exception as e:
      echo e.msg

  asyncCheck doServe(callback)

  when WithSsl:
    asyncCheck doServeSecure(callback)
    
  runForever()


proc emit*() {.gcsafe.} =
  ## run katalis
  serve()
