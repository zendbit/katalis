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
### 3.2.1 Initialize pipeline
Initialize pipeline will be eveluate on katalis initialization when katalis start.
|Filename|Description|
|--------|-----------|
|taskMonitor|this will start task monitor for katalis|
We can also add custom task, to start with schedules like cron job
### 3.2.1 Before pipeline
Before pipeline will be evaluate before route processing happen, this pipeline has advantages like early checking like authentication. Katalis has some predefines before pipelines
|Filename|Description|
|--------|-----------|
|http.nim|handle http request from client (get, post, head, etc)|
|httpRanges.nim|handle http ranges request from client|
|session.nim|session initialization|
|webSocket.nim|handle web socket request from client, if http protocol upgrade request present|
## 4. Katalis DSL (Domain Specific Language)

## 5. Configuration

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
