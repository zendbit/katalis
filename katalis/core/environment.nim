##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## Shared environment
##


import std/
[
  tables,
  os
]
from std/nativesockets import Port


import
  ../utils/debug

export
  debug


type
  SslSettings* = ref object of RootObj
    ## SslSettings type for secure connection

    certFile*: string ## \
    ## path to certificate file (.pem)
    keyFile*: string ## \
    ## path to private key file (.pem)
    enableVerify*: bool ## \
    ## verify mode
    ## verify = false -> use SslCVerifyMode.CVerifyNone for self signed certificate
    ## verify = true -> use SslCVerifyMode.CVerifyPeer for valid certificate
    port*: Port ## \
    ## port for ssl
    caDir*: string ## \
    ## for CVerifyPeerUseEnvVars
    caFile*: string ## \
    ## for CVerifyPeerUseEnvVars
    enableUseEnv*: bool ## \
    ## for CVerifyPeerUseEnvVars


  Settings* = ref object of RootObj
    ## settings type object
  
    port*: Port ## \
    ## port for unsecure connection (http)
    address*: string ## \
    ## address to bind
    enableReuseAddress*: bool ## \
    ## resuse address
    enableReusePort*: bool ## \
    ## reuser port
    enableTrace*: bool ## \
    ## trace mode
    sslSettings*: SslSettings ## \
    ## SslSettings instance type
    enableBroadcast*: bool ## \
    ## socket option OptBroadcast
    enableDontRoute*: bool ## \
    ## socket option OptDontRoute
    enableOOBInline*: bool ## \
    ## socket option OptOOBInline
    enableKeepAlive*: bool ## \
    ## socket option OptKeepAlive
    ## Keep-Alive header max request with given persistent timeout
    ## read RFC (https://tools.ietf.org/html/rfc2616)
    ## section Keep-Alive and Connection
    ## for improving response performance
    maxRecvSize*: int64 ## \
    ## max body length server can handle
    ## can be vary on setting
    ## value in bytes
    storagesDir*: string ## \
    ## storage working directory
    storagesUploadDir*: string ## \
    ## storage upload directory
    readRecvBuffer*: int ## \
    ## read body buffer
    storagesBodyDir*: string ## \
    ## storage body for request/response process
    storagesSessionDir*: string ## \
    ## storage session for request/response process
    staticDir*: string ##\
    ## static directory to serve
    enableServeStatic*: bool ##\
    ## enable/disable serve static directory
    chunkSize*: int ## \
    ## chunked size transfer encoding size block
    maxSendSize*: int ## \
    ## max data can send from server
    ## when client request
    ## use ranges if
    ## data is big
    enableChunkedTransfer*: bool ## \
    ## enable chunked transfer encoding
    enableRanges*: bool ## \
    ## enable ranges as bytes request
    ## accept-ranges: bytes
    rangesSize*: int ## \
    ## range size to split
    enableCompression*: bool ## \
    ## enable compression check
    ## if client support accept-encoding: gzip
    ## then do compression on response
    maxBodySize*: int ## \
    ## set maximum body size
    ## to prevent sending big file from client
    ## save serve from flooding


  Environment* = ref object of RootObj
    ## Environment type object

    settings*: Settings ## \
    ## sever settings and configuration
    shared*: TableRef[string, string] ## \
    ## shared environment as hashtable TableRef[string, string]


proc newSettings*(
    address: string = "0.0.0.0",
    port: Port = Port(8000),
    enableReuseAddress: bool = true,
    enableReusePort:bool = true,
    sslSettings: SslSettings = nil,
    maxRecvSize: int64 = 209715200,
    enableKeepAlive: bool = true,
    enableOOBInline: bool = false,
    enableBroadcast: bool = false,
    enableDontRoute: bool = false,
    storagesDir: string = getCurrentDir().joinPath("storages"),
    storagesUploadDir: string = getCurrentDir().joinPath("storages", "upload"),
    storagesBodyDir: string = getCurrentDir().joinPath("storages", "body"),
    storagesSessionDir: string = getCurrentDir().joinPath("storages", "session"),
    staticDir: string = getCurrentDir().joinPath("static"),
    enableServeStatic: bool = false,
    readRecvBuffer: int = 524288,
    enableTrace: bool = false,
    chunkSize: int = 16384,
    maxSendSize: int = 52428800,
    enableChunkedTransfer: bool = true,
    enableRanges: bool = true,
    rangesSize: int = 2097152,
    enableCompression: bool = true,
    maxBodySize: int = 52428800
  ): Settings {.gcsafe.} =
  ## new server configuration

  result = Settings(
      address: address,
      port: port,
      enableReuseAddress: enableReuseAddress,
      enableReusePort: enableReusePort,
      sslSettings: sslSettings,
      maxRecvSize: maxRecvSize,
      enableKeepAlive: enableKeepAlive,
      enableOOBInline: enableOOBInline,
      enableBroadcast: enableBroadcast,
      enableDontRoute: enableDontRoute,
      storagesDir: storagesDir,
      storagesUploadDir: storagesUploadDir,
      storagesBodyDir: storagesBodyDir,
      storagesSessionDir: storagesSessionDir,
      staticDir: staticDir,
      enableServeStatic: enableServeStatic,
      readRecvBuffer: readRecvBuffer,
      enableTrace: enableTrace,
      chunkSize: chunkSize,
      maxSendSize: maxSendSize,
      enableChunkedTransfer: enableChunkedTransfer,
      enableRanges: enableRanges,
      rangesSize: rangesSize,
      enableCompression: enableCompression,
      maxBodySize: maxBodySize
    )


proc newSslSettings*(
    certFile: string,
    keyFile: string,
    port: Port = Port(8443),
    enableVerify: bool = false,
    caDir: string = "",
    caFile: string = "",
    enableUseEnv: bool = false
  ): SslSettings {.gcsafe.} =
  ## new ssl server configuration

  SslSettings(
    certFile: certFile,
    keyFile: keyFile,
    enableVerify: enableVerify,
    port: port
  )


proc newEnvironment*(): Environment {.gcsafe.} =
  ## create new environment

  Environment(
    settings: newSettings(),
    shared: newTable[string, string]()
  )


# create shared global ENV
var environmentInstance {.threadvar.}: Environment
environmentInstance = newEnvironment()


proc instance*(): Environment {.gcsafe.} =
  ## return env shared instance

  environmentInstance
