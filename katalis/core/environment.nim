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
  paths
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
    storagesDir*: Path ## \
    ## storage working directory
    storagesUploadDir*: Path ## \
    ## storage upload directory
    readRecvBuffer*: int ## \
    ## read body buffer
    storagesBodyDir*: Path ## \
    ## storage body for request/response process
    storagesSessionDir*: Path ## \
    ## storage session for request/response process
    storagesCacheDir*: Path ## \
    ## storage for cache file
    staticDir*: Path ##\
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


  Environment* = ref object of RootObj
    ## Environment type object

    settings*: Settings ## \
    ## sever settings and configuration
    shared*: JsonNode ## \
    ## shared environment as JsonNode


proc newSettings*(
    address: string = "0.0.0.0",
    port: Port = Port(8000),
    enableReuseAddress: bool = true,
    enableReusePort:bool = true,
    sslSettings: SslSettings = nil,
    maxRecvSize: int64 = 104857600,
    enableKeepAlive: bool = true,
    enableOOBInline: bool = false,
    enableBroadcast: bool = false,
    enableDontRoute: bool = false,
    storagesDir: Path = getCurrentDir()/"storages".Path,
    storagesUploadDir: Path = getCurrentDir()/"storages".Path/"upload".Path,
    storagesBodyDir: Path = getCurrentDir()/"storages".Path/"body".Path,
    storagesSessionDir: Path = getCurrentDir()/"storages".Path/"session".Path,
    storagesCacheDir: Path = getCurrentDir()/"storages".Path/"cache".Path,
    staticDir: Path = getCurrentDir()/"static".Path,
    enableServeStatic: bool = false,
    chunkSize: int = 8129,
    readRecvBuffer: int = 32768,
    enableTrace: bool = false,
    maxSendSize: int = 32768,
    enableChunkedTransfer: bool = true,
    enableRanges: bool = true,
    rangesSize: int = 32768,
    enableCompression: bool = true
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
      storagesCacheDir: storagesCacheDir,
      staticDir: staticDir,
      enableServeStatic: enableServeStatic,
      chunkSize: chunkSize,
      readRecvBuffer: readRecvBuffer,
      enableTrace: enableTrace,
      maxSendSize: maxSendSize,
      enableChunkedTransfer: enableChunkedTransfer,
      enableRanges: enableRanges,
      rangesSize: rangesSize,
      enableCompression: enableCompression
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
    shared: %*{}
  )


# create shared global ENV
var environmentInstance {.threadvar.}: Environment
environmentInstance = newEnvironment()


proc instance*(): Environment {.gcsafe.} =
  ## return env shared instance

  environmentInstance
