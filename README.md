# katalis
Katalis is [nim lang](https://nim-lang.org) micro framework

## 1. Install
```
nimble install katalis
```

## 2. Running simple app
After installing katalis, you can simply create your first app by import *katalisApp*
```nim
import katalis/katalisApp
```

Katalis has some macros for it's own DSL. Katalis use *@!* as macros prefix (We will explore about katalis DSL on the next section).

Create directory for the app
```bash
mkdir simpleapp
cd simpleapp
```

Create nim source file, in this case we will use *app.nim*
```nim
import katalis/katalisApp

## lets do some basics configuration
@!Settings.enableServeStatic = true
@!Settings.enableKeepAlive = true
## we also can use custom port
#@!Settings.port = Port(8080)

## lets start simple app
@!App:
  @!Get "/":
    @!Context.reply(Http200, "<h1>Hello World!.</h1>")

## kick and start the app
@!Emit
```

Compile the source with --threads:on switch to enable thread support and run it!
```bash
nim c -r --threads:on app.nim
```

Katalis will run on port 8000 as default port
```bash
Listening non secure (plain) on http://0.0.0.0:8000
```

Lets open with the browser [http://localhost:8000](http://localhost:8000)

![Alt http://localhost:8000](https://github.com/zendbit/katalis-readme-assets/blob/981946bf0fee5acaa341edc04ed3e26f82263e5c/Screenshot%20From%202024-11-03%2021-38-44.png)
--threads:on
## 3. Katalis structure
Internal katalis structure is devided into some folders structure
### 3.1 core (folder)
Core folder contains base katalis framework it's focused on http protocol implementataion and some protocols enhancements
|Filename|Description|
|--------|-----------|
|constants.nim|contains constans declaration used by katalis|
|environment.nim|contains shared environment (settings, shared threads variable)|
|form.nim|contains functionalities for construct form (urlencoded, data)|
|httpContext.nim|contains http context per client request (cookie, request, response)|
|katalis.nim|katalis object type and instance|
|multipart.nim|contains functionality for construct multipart data|
|replyMsg.nim|universal response message to client|
|request.nim|request object type used by http context|
|response.nim|response object type used by http context|
|routes.nim|route object type and instance, contains funtionalities for handling route request|
|session.nim|contains funtionalities for handling cookies|
|staticFile.nim|contains funtionalities for handling static file|
|webSocket.nim|websocket object type for handling websocket request|
### 3.2 Pipelines (folder)
Pipelines in katalis is like middleware, it will process request from client and response with appropriate response. Katalis has some pipelines
|Pipelines|Descriptions|
|---------|------------|
|after|this will be evaluate after route process|
|before|this will be evaluate before route process|
|initialize|will be eveluate on katalis initialization when katalis start|
|onReply|will be evaluate before response message to client, this usually used for modified response message|

#### 3.2.1 Initialize pipelines
Initialize pipeline will be eveluate on katalis initialization when katalis start.
|Filename|Description|
|--------|-----------|
|taskMonitor.nim|this will start task monitor for katalis|

We can also add custom task with schedules like cron job

#### 3.2.2 Before pipelines
Before pipeline will be evaluate before route processing, this pipeline has advantages like early checking like authentication. Katalis has some predefines before pipelines
|Filename|Description|
|--------|-----------|
|http.nim|handle http request from client (get, post, head, etc)|
|httpRanges.nim|handle http ranges request from client|
|session.nim|session initialization|
|webSocket.nim|handle web socket request from client, if http protocol upgrade request present|

#### 3.2.3 After pipelines
After pipeline will be evaluate after route processing, this pipelines has advantages like early checking if request has access to route resource or not
|Filename|Description|
|--------|-----------|
|httpStaticFile|handle static file request from client|

Static file must be placed is in *static* folder, but we can also changes default static folder from configuration (For more information about configuration see configuration section).

#### 3.2.4 OnReply pipelines
OnReply pipeline will be evaluate before sending response to client, this pipeline used for modifying payload.
|Filename|Description|
|--------|-----------|
|httpChunked.nim|handle chunked payload response, default is chunked as http standard|
|httpComposePayload.nim|handle composing payload header + body for response|
|httpCompress.nim|handle compression support (gzip) if client support zip compression|

#### 3.2.5 Cleanup pipelines
Clenup pipeline will evaluate after sending response to client, this pipeline will evaluate after all process response to client finished.
|Filename|Description|
|--------|-----------|
|httpContext.nim|will cleanup unused cache data related with http context|

### 3.3 Macros (folder)
Macros folder contains macros definition for katalis framework
|Filename|Description|
|--------|-----------|
|sugar.nim|macros definition for katalis DSL (Domain Specific Language)|

More information about DSL, see DSL (Domain Specific Languate) section

### 3.4 Utils (folder)
Utilities and helper for katalis framework
|Filename|Description|
|--------|-----------|
|crypt.nim|some cryptohraphy algorithm|
|debug.nim|debug msg|
|httpcore.nim|http core stdlib extension|
|json.nim|some json stdlib extension|

### 3.5 Extension (folder)
Internal extension for katalis framework
|Filename|Description|
|--------|-----------|
|mustache.nim|mustache template engine using [mustachu](https://github.com/fenekku/moustachu) nimble pkg|
|taskMonitor.nim|simple cron job for katalis|
|validation.nim|simplify validation for form, json, and Table[string, string]|

### 3.6 KatalisApp (file)
Katalis application, this is starting poin of katalis framework. Includes all file needed for developing katalis application.
|Filename|Description|
|--------|-----------|
|katalisApp.nim|include this file for starting the app server|

### 3.7 Pipeline (file)
Katalis pipeline contains include declaration for katalis pipelines order, include declaration is important depend on this order:
- initialize
- before
- after
- onReply
- cleanup

|Filename|Description|
|--------|-----------|
|pipeline.nim|pipeline order includes declaration|

## 4. Katalis DSL (Domain Specific Language)
Katalis come with Domain Specific Language, the purpose using DSL is for simplify the development and write less code. Katalis using *@!* prefix for the DSL to prevent confict and make it easy for coding convention. Katalis DSL available in *katalis/macros/sugar.nim*. There are some macros that only can be called inside *@!App* block and block pipeline in katalis let see the table.

Available on outside *@!App* block
|Name|Description|
|----|-----------|
|@!Settings|katalis settings instance, related to Settings type object in katalis/core/environment.nim|
|@!Emit|start katalis app, related to Katalis type object in katalis/core/katalis.nim|
|@!Routes|katalis routes object instance, related to Route type object in katalis/core/routes.nim|
|@!Katalis|katalis object instance, related to Katalis type object in katalis/core/katalis.nim|
|@!Environment|katalis environment instance, related to Environment type object in katalis/core/environment.nim|
|@!SharedEnv|katalis shared Table[string, string] type object for sharing between the app instance, related to Environment type object in katalis/core/environment.nim|
|@!Trace|trace block for displaying debug message, available when @!Settings.enableTrace = true|

Available only inside *@!App* block
|Name|Description|
|----|-----------|
|@!Before|before route block pipeline|
|@!After|after route block pipeline|
|@!OnReply|on reply pipeline|
|@!Cleanup|cleanup pipeline|
|@!EndPoint|set endpoint for each route prefix (Optional)|
|@![Get, Post, Patch, Delete, Put, Options, Trace, Head, Connect]|http method for routing|
|@!Context|http context route parameter, related to HttpContext type object in katalis/core/httpContext.nim|
|@!Env|environment route parameter, related to Environment type object in katalis/core/environment.nim|
|@!Req|request context from client, related to Request type object in katalis/core/request.nim|
|@!Res|response context to client, related to Response type object in katalis/core/response.nim|
|@!WebSocket|websocket context service, related to WebSocket type object in katalis/core/webSocket.nim|
|@!Client|socket client context, related to AsyncSocket type object in katalis/core/httpContext.nim|
|@!Body|request body from client, related to Request type object field in katalis/core/request.nim|
|@!Segment|path segment url from client request, related to RequestParam type object in katalis/core/request.nim also related to Table[string, string] nim stdlib|
|@!Query|query string from client request, related to RequestParam type object in katalis/core/request.nim also related to Table[string, string] nim stdlib|
|@!Json|json data from client request, related to RequestParam type object in katalis/core/request.nim also related to JsonNode nim stdlib|
|@!Xml|xml data from client request, related to RequestParam type object in katalis/core/request.nim also related to XmlNode nim stdlib|
|@!Form|form data from client will handle form urlencode/multipart, related to Form type object in katalis/core/form.nim|

DSL Code structure in Katalis
```nim
## available on global
## @!Settings
## @!Emit -> Should called after @!App block
## @!Route
## @!Katalis
## @!Environment
## @!SharedEnv
## @!Trace

## katalis app block
@!App:
  ## code here

  ## endpoint optional, this endpoint prefix path will append to each route path request
  ## this is optional, and should be define before all other pipeline
  @!EndPoint "/test/api"

  ## before route block
  @!Before:
    ## available here
    ## @!Context
    ## @!Req
    ## @!Res
    ## @!Env
    ## @!Res
    ## @!WebSocket
    ## @!Client
    ## @!Body
    ## @!Segment
    ## @!Query
    ## @!Json
    ## @!Xml
    ## @!Form
    ## also global katalis macros

    ## code here

  ## after route block
  @!After:

    ## code here

  ## on reply block
  @!OnReply:

    ## code here

  ## cleanup block
  @!Cleanup:

    ## code here


  ## routing
  ## available method @!Get, @!Post, @!Put, @!Delete, @!Patch, @!Head, @!Connect, @!Options, @!Trace
  @!Post "/register":

    ## code here

  @!Get "/home":

    ## code here

  ## also support for multiple method on routing
  @![Get, Post] "/login":

    ## code here
```

## 5. Configuration
Configuration can be set using *@!Settings* macro. See katalis/core/environment.nim (Settings object type)
```nim
@!Settings.address = "0.0.0.0" ## default
@!Settings.port = Port(8000) ## default

## available settings (default value, all size metric in bytes):
## address: string = "0.0.0.0"
## port: Port = Port(8000)
## enableReuseAddress: bool = true
## enableReusePort:bool = true
## sslSettings: SslSettings = nil
## maxRecvSize: int64 = 209715200
## enableKeepAlive: bool = true
## enableOOBInline: bool = false
## enableBroadcast: bool = false
## enableDontRoute: bool = false
## storagesDir: string = getCurrentDir().joinPath("storages")
## storagesUploadDir: string = getCurrentDir().joinPath("storages", "upload")
## storagesBodyDir: string = getCurrentDir().joinPath("storages", "body")
## storagesSessionDir: string = getCurrentDir().joinPath("storages", "session")
## staticDir: string = getCurrentDir().joinPath("static")
## enableServeStatic: bool = false
## readRecvBuffer: int = 524288
## enableTrace: bool = false
## chunkSize: int = 16384
## maxSendSize: int = 52428800
## enableChunkedTransfer: bool = true
## enableRanges: bool = true
## rangesSize: int = 2097152
## enableCompression: bool = true
## maxBodySize: int = 52428800
```

## 6. Serve static file
in progress

## 7. Create routes and handling request
in progress

## 8. Query string, form (urlencoded/multipart), json
in progress

## 9. Validation
in progress
## 10. Template engine (Mustache)
in progress

## 11. Websocket
in progress

## 12. SSL
in progress

## 13. Create extensions
in progress

## 14. Fullstack
in progress
