# Gold Sponsor
<table>
  <tr>
    <td>
    <a href="https://amscloud.co.id"><img src="https://github.com/zendbit/katalis-readme-assets/blob/f146951204bb7f941412d9becc8fa64c6cf7f5e0/Banner_Awan%20Media%20Semesta_600_BG.png" height="100px"></a>
    <a href="https://superserver.co.id"><img src="https://github.com/zendbit/katalis-readme-assets/blob/f146951204bb7f941412d9becc8fa64c6cf7f5e0/Banner_Super%20Server_600%20(1)_BG.png" height="100px"></a>
    <br>
    <a href="https://wisatech.co.id"><img src="https://github.com/zendbit/katalis-readme-assets/blob/68132bf0ae335fd61c071d9bfb7f42483be3873a/WhatsApp%20Image%202024-11-10%20at%2000.58.36.jpeg" height="100px"></a>   
    </td>
    <td>
    <a href="https://www.facebook.com/kandangretawu"><img src="https://github.com/zendbit/katalis-readme-assets/blob/02ca1a457bba7d678d554cf5e931742ed8a955e1/326268483_1219408249008756_5424435258872438740_n.png" height="200px"></a>
    </td>
  </tr>
</table>

# Katalis
Katalis is [nim lang](https://nim-lang.org) micro web framework

Katalis always focusing on protocol implementation and performance improvement. For fullstack framework using katalis it will be depends on developer needs, we will not provides frontend engine or database layer engine (ORM) because it will vary for each developer taste!.

If you want to use katalis as fullstack nim, you can read on fullstack section in this documentation.

## 1. Install
```bash
nimble install katalis
```

If some reason failed to install using nimble directory, you can install directly from the github
```bash
nimble install https://github.com/zendbit/katalis
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

Compile the source with --threads:on switch to enable thread support and run it!.
```bash
nim c -r --threads:on app.nim
```

Katalis also support for chronos async/await framework [https://github.com/status-im/nim-chronos](https://github.com/status-im/nim-chronos) as asyncdispatch backend
```bash
nim c -r --thread:on -d:asyncBackend=chronos
```

Katalis will run on port 8000 as default port
```bash
Listening non secure (plain) on http://0.0.0.0:8000
```

Lets open with the browser [http://localhost:8000](http://localhost:8000)

![Alt http://localhost:8000](https://github.com/zendbit/katalis-readme-assets/blob/981946bf0fee5acaa341edc04ed3e26f82263e5c/Screenshot%20From%202024-11-03%2021-38-44.png)

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
|httpStaticFile.nim|handle static file request from client|

Static file must be placed is in *static* folder, but we can also changes default static folder from configuration (For more information about configuration see configuration section).

#### 3.2.4 OnReply pipelines
OnReply pipeline will be evaluate before sending response to client, this pipeline used for modifying payload.
|Filename|Description|
|--------|-----------|
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
|httpcore.nim|http core stdlib [plugins|](plugins|)
|json.nim|some json stdlib plugins|

### 3.5 Plugins (folder)
Internal plugins for katalis framework
|Filename|Description|
|--------|-----------|
|nimMustache.nim|mustache template engine using [mustache](https://github.com/soasme/nim-mustache) nimble pkg|
|taskMonitor.nim|simple cron job for katalis|
|validation.nim|simplify validation for form, json, and Table[string, string]|

### 3.6 KatalisApp (file)
Katalis application, this is starting poin of katalis framework. Includes all file needed for developing katalis application.
|Filename|Description|
|--------|-----------|
|katalisApp.nim|include this file for starting the app server|

### 3.7 Pipelines (file)
Katalis pipeline contains include declaration for katalis pipelines order, include declaration is important depend on this order:
- initialize
- before
- after
- onReply
- cleanup

|Filename|Description|
|--------|-----------|
|pipelines.nim|pipeline order includes declaration|

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
## maxRecvSize: int64 = 104857600
## enableKeepAlive: bool = true
## enableOOBInline: bool = false
## enableBroadcast: bool = false
## enableDontRoute: bool = false
## storagesDir: string = getCurrentDir()/"storages".Path
## storagesUploadDir: string = getCurrentDir()/"storages".Path/"upload".Path
## storagesBodyDir: string = getCurrentDir()/"storages".Path/"body".Path
## storagesSessionDir: string = getCurrentDir()/"storages".Path/"session".Path
## staticDir: string = getCurrentDir()/"static".Path
## enableServeStatic: bool = false
## chunkSize: int = 8129
## readRecvBuffer: int = 32768
## enableTrace: bool = false
## maxSendSize: int = 104857600
## enableRanges: bool = true
## rangesSize: int = 32768
## enableCompression: bool = true
```

## 6. Serve static file

Serving static file size default value is arround 100M max, if you want to
increase max send file size value you can increase @!Settings.maxSendSize. But
be mindfull, make sure you have good server resource to handle it.

### Serve individual file with app route
```nim
@!App:
  @!Get "/my-picture-profile":
    @!Context.replySendFile("my-profile-image.png".Path)

  @!Get "/my-funny-video":
    @!Context.replySendFile("funny-video.mp4".Path)
```

### Serve plugin static file
For serving static file like static html, css, image, video, etc. We only need to enable *enableServeStatic* in katalis settings.

Lets create *serverstatic-example* folder.
```bash
mkdir servestatic-example
cd servestatic-example
```

Then create *static* folder inside *servestatic-example* folder
```bash
mkdir static
```

Inside *servestatic-example* folder we create minimal katalis app for serving static file. In this case we create *app.nim*
```nim
import katalis/katalisApp

## enable static file service
@!Settings.enableServeStatic = true
@!Settings.enableKeepAlive = true

@!Emit
```

Compile and start the server
```bash
nim c -r app.nim
```

Don't forget to put your static files into *static* folder

![Alt static folders](https://github.com/zendbit/katalis-readme-assets/blob/94adfbcf3d80eb3eaec2d60974203b7c1737382a/Screenshot%20From%202024-11-09%2016-09-16.png)

Open with browser [http://localhost:8000/index.html](http://localhost:8000/index.html)

## 7. Create routes and handling request
```nim
import katalis/katalisApp
import katalis/plugins/nimMustache

@!Settings.enableServeStatic = true
@!Settings.enableKeepAlive = true

@!App:
  ## we can also create prefix for all routes
  @!EndPoint "/admin" ## \
  ## all routes will prefixed with /admin/

  ## get request for default /
  ## in this case, because we already set @!EndPoint to "/admin"
  ## so the route url will be http://localhost:8000/admin
  @!Get "/":
    await @!Context.reply(Http200, "<h1>This is admin the root page!")

  ## another get example
  ## http://localhost:8000/hello
  @!Get "/hello":
    await @!Context.reply(Http200, "<h1>world!</h1>")

  ## mapping route, retrieve segment to variable
  @!Get "/birthdate/:month/:day/:year":
    ## this will retrieve segments
    ## as variable month, day, and year
    ## http://localhost/admin/birthdate/may/22/2000
    
    let birthdate = [@!Segment["month"],  @!Segment["day"], @!Segment["year"]].join("/")

    await @!Context.reply(
      Http200,
      &"<h3>Birthdate</h3> <p>{birthdate}</p>"
    )

  ## mapping route, retrieve query string to variable
  @!Get "/birthdate":
    ## this will retrieve query string
    ## as variable month, day, and year
    ## http://localhost/admin/birthdate?month=may&day=22&year=2000
    
    let birthdate = [@!Query.getOrDefault("month"),  @!Query.getOrDefault("day"), @!Query.getOrDefault("year")].join("/")

    await @!Context.reply(
      Http200,
      &"<h3>Birthdate</h3> <p>{birthdate}</p>"
    )

  ## mapping route, retrieve segment as regex pattern
  @!Get "/birthdate/re<:month([a-zA-Z]+)_:day([0-9]+)_:year([0-9]+)>":
    ## this will retrieve query string
    ## as variable month, day, and year
    ## http://localhost/admin/birthdate/may_22_2000
    
    let birthdate = [@!Segment.getOrDefault("month"),  @!Segment.getOrDefault("day"), @!Segment.getOrDefault("year")].join("/")

    await @!Context.reply(
      Http200,
      &"<h3>Birthdate</h3> <p>{birthdate}</p>"
    )

  ## we also can have multiple method
  ## in one route definition
  @![Get, Post] "/login":
    ## we can use validation to check fields
    ## but for validation details we will discuss in other section
    ## about validation

    ## let get form data username, password
    ## if method http post validate the form data
    let username = @!Form.data.getOrDefault("username")
    let password = @!Form.data.getOrDefault("password")
    var errorMsg = ""
    if @!Req.httpMethod == HttpPost:
      if username == "" or password == "":
        errorMsg = "username or password is required!"

    ##
    ## katalis come with mustache template engine
    ## for template engine we will explain later
    ##
    let tpl = 
      """
        <html>
          <head>
            <title>example</title>
          </head>
          <body>
            <h3>Login</h3>
            <form method="POST">
              <input type="text" name="username" placeholder="username" value="{{username}}">
              <br>
              <input type="password" name="password" placeholder="password" value="{{password}}">
              <br>
              <input type="submit" value="Login">
            </form>
            <h4>{{errorMsg}}</h4>
          </body>
        </html>
      """

    let m = newMustache()
    m.data["errorMsg"] = errorMsg
    m.data["username"] = username
    m.data["password"] = password
    @!Context.reply(Http200, m.render(tpl))

## we can have multiple @!App for routes separation
@!App:
  ## let definde endpoint for users
  @!EndPoint "/user"

  ## the user root page
  ## http://localhost:8000/user
  @!Get "/":
    await @!Context.reply(Http200, "<h1>This is user root page</h1>")

@!Emit
```

## 8. Query string, form (urlencoded/multipart), json, xml, upload, Redirect, Session
### 8.1 Handling query string request
```nim
import katalis/katalisApp

@!Settings.enableServeStatic = true
@!Settings.enableKeepAlive = true

@!App:
  @!Get "/test-qs":
    ## lets do query string test
    ## http://localhost:8000/test-qs?city=ngawi&province=surabaya with get method
    let city = @!Query.getOrDefault("city")
    let province = @!Query.getOrDefault("province")

    @!Context.reply(Http200, &"<h3>Welcome to {province}, {city}.</h3>")
```

### 8.2 Handling form data
```nim
import katalis/katalisApp

@!Settings.enableServeStatic = true
@!Settings.enableKeepAlive = true

@!App:
  @!Post "/test-form":
    ## lets do form test
    ## http://localhost:8000/test-form with post method
    let city = @!Form.data.getOrDefault("city")
    let province = @!Form.data.getOrDefault("province")

    @!Context.reply(Http200, &"<h3>Welcome to {province}, {city}.</h3>")
```

### 8.3 Handling JSON data
All json request data will convert to nim stdlib json see [https://nim-lang.org/docs/json.html](https://nim-lang.org/docs/json.html)
```nim
import katalis/katalisApp

@!Settings.enableServeStatic = true
@!Settings.enableKeepAlive = true

@!App:
  @!Post "/test-json":
    ## lets do json test
    ## http://localhost:8000/test-json with post method
    let data = @!Json ## \
    ## json data from client request
    ## all data will convert to nim stdlib JsonNode
    ## see https://nim-lang.org/docs/json.html

    ## lets modify the data add country to json
    data["country"] = %"indonesia"

    ## katalis will automatic response as json if we pass JsonNode
    ## lets pass JsonNode from client and we modify it
    await @!Context.replyJson(Http200, data)
```

### 8.4 Handling XML data
All xml request data will convert to nim stdlib xmltree see [https://nim-lang.org/docs/xmltree.html](https://nim-lang.org/docs/xmltree.html)
```nim
  @!Post "/test-xml":
    ## lets do xml test
    ## http://localhost:8000/test-xml with post method
    let data = @!Xml ## \
    ## xml data from client request
    ## all data will convert to nim stdlib XmlNode
    ## see https://nim-lang.org/docs/xmltree.html
    ##
    ## Try to send data using this xml format
    ##  <Address>
    ##    <City>Ngawi</City>
    ##    <Province>Surabaya</Province>
    ##  </Address>
    ##

    ## lets modify the data add country
    let country = newElement("Country")
    country.add(newText("Indonesia"))
    data.add(country)

    ## katalis will automatic response as xml if we pass XmlNode
    ## lets pass XmlNode from client and we modify it
    await @!Context.replyXml(Http200, data)
```
### 8.5 Handling uploaded files
```nim
  @![Get, Post] "/test-upload":
    ## lets do upload multipart data
    ## katalis come with mustache template engine
    ## for template engine we will explain later
    ##
    let tpl = 
      """
        <html>
          <head>
            <title>upload test</title>
          </head>
          <body>
            <h3>Upload files</h3>
            <form method="POST" enctype="multipart/form-data">
              Upload Single
              <br>
              <input name="onefile" type="file" />
              <br>
              <br>
              Upload Multiple
              <br>
              <input name="multiplefiles[]" type="file" multiple />
              <br>
              <br>
              <button type="submit">Upload</button>
            </form>
          </body>
        </html>
      """

    if @!Req.httpMethod == HttpPost:
      ## test show uploaded file info to console
      if @!Form.files.len != 0:
        for name, files in @!Form.files:
          echo name
          for file in files:
            echo file.plugins
            echo file.path
            echo file.mimetype
            echo file.isAccessible

      ## create directory uploaded if not exist
      if not "uploaded".dirExists:
        "uploaded".createDir

      ## check if files exists
      if "onefile" in @!Form.files:
        let onefile = @!Form.files["onefile"][0]
        ## move files to uploaded dir
        onefile.path.moveFile("uploaded".Path/onefile.Path)

      if "multiplefiles" in @!Form.files:
        let multiplefiles = @!Form.files["multiplefiles"]
        for file in multiplefiles:
          ## move files to uploaded dir
          file.path.moveFile("uploaded"/file.name.Path)

    let m = newMustache()
    @!Context.reply(Http200, m.render(tpl))
```
### 8.6 Redirect
We can modify response header for redirection purpose
```nim
@!App:
  @!Get "/home":
    @!Context.reply(Http200, "<h3>Welcome home!</h3>")

  @!Get "/test-redirect":
    ## modify response header add redirect location to /home
    @!Res.headers["Location"] = "/home"
    @!Context.reply(Http307, "")
```
### 8.7 Session
See *katalis/core/session.nim*
```nim
@!App:
  ## init cookie session
  @!Before:
    await @!Context.initCookieSession()

  @!Get "/hello":
    await @!Context.addCookieSession("name", %"Tian Long")
    let name = await @!Context.getCookieSession("name")
    ## remove individual session with @!Context.deleteCookieSession("name")
    ## destroy all session value with @!Context.destroyCookieSession()
    await @!Context.reply(Http200, &"Hello {name}!")
```
## 9. Before, After, OnReply, Cleanup Pipelines
### 9.1 Before pipeline
Before pipeline will execute before routing process, also before serving staticfile. We can use it to check for all route before route process. We can skip all route by returning *true* statement
```nim
@!App:
  @!Before:
    ## your code here

    if something_wrong:
      @!Context.reply(Http403, "Anauthorized access!")
      ## by returning true, will skip all process and return the error message, this is simplify for checking
      return true
```
### 9.2 After pipeline
After pipeline will execute after routing process, also after serving staticfile
```nim
@!App:
  @!After:
    ## your code here

    if something_wrong:
      @!Res.headers["Location"] = "/home"
      @!Context.reply(Http307, "")
      ## return true for skip all routing definition
      return true
```
### 9.3 OnReply
OnReply pipeline will process before sending request to client, we can modify for all response from route. This example is from katalis/pipelines/onReply/httpCompress.nim, will compress before zending to client
```nim
##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## add pipeline on onreply
## check if client support compression then compress
##


import zippy


import
  ../../core/routes,
  ../../macros/sugar,
  ../../core/environment


@!App:
  @!OnReply:
    # if client support gzip
    # and enableCompression enabled
    if "gzip" in
      @!Req.headers.getValues("accept-encoding") and
      @!Settings.enableCompression:

      @!Res.headers["content-encoding"] = "gzip"
      @!Res.body = compress(@!Res.body, BestSpeed, dfGzip)
```
### 9.4 Cleanup
Cleanup pipeline will process after all pipeline finished, this usually for cleanup resource. This example is from katalis/pipelines/cleanup/httpContext.nim
```nim
##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## Cleanup body request cache
##


import
  ../../core/routes,
  ../../macros/sugar,
  ../../core/environment


@!App:
  @!Cleanup:
    if @!Req.body.fileExists:
      @!Req.body.removeFile

    if @!Req.param.form.files.len != 0:
      ## remove file after file uploaded
      ## uploaded file should be move after finished
      ## file uploaded before cleanup present
      for _, files in @!Req.param.form.files:
        for file in files:
          if not file.isAccessible or not file.path.fileExists:
            continue

          file.path.removeFile

    ## clear http context
    @!Context.clear

```
## 10. Response Message
Response message is universal response message, using this response message will always response application/json. See *katalis/core/replyMsg*
```nim
@!App:
  @!Get "/test-replymsg":
    ## see core katalis/core/replyMsg.nim
    @!Context.reply(newReplyMsg(
      httpCode = Http200,
      success = true,
      data = %*{
        "username": "tian",
        "address": "Guangdong"
      },
      error = %*{}
    ))
```
## 11. Validation
Katalis comes with validations feature. See katalis/plugins/validation.nim.

Available validations are:
- isRequired
- isEmail
- minValue
- maxValue
- minLength
- maxLength
- isDateTime
- minDateTime
- maxDateTime
- inList
- matchWith -> regex validation
```nim
@!App:
  @![Get, Post] "/test-validation":
    ## validation is plugins on katalis
    ## see katalis/plugins/validation.nim
    let tpl =
      """
        <html>
          <head><title>validation test</title></head>
          <body>
            <form method="POST">
              <label>Username<label> <span>{{username.msg}}</span>
              <br>
              <input type="text" name="username" value="{{username.value}}">
              <br>
              <br>
              <label>Password</label> <span>{{password.msg}}</span>
              <br>
              <input type="password" name="password" value="{{password.value}}">
              <br>
              <br>
              <input type="submit" value="Register">
            </form>
          </body>
        </html>
      """
    
    ## mustache template
    let m = newMustache()

    if @!Req.httpMethod == HttpPost:
      ## parameter can be Form, JsonNode or Table[string, string] type
      let v = newValidation(@!Form)
      v.withField("username").
        isRequired(failedMsg = "Username is empty."). ## we can add custom failedMsg
        minLength(8). ## minimum length of field value is 8 char length
        maxLength(50). ## maximum length of field value is 50 char length
        matchWith("([a-zA-Z0-9_]+)$", failedMsg = "Only a-z A-Z 0-9 _ are allowed") ## check with regex, only allow a-z A-Z 0-9 _

      v.withField("password").
        isRequired(failedMsg = "Password is empty."). ## we can add custom failedMsg
        minLength(8). ## minimum length 8 char length
        maxLength(254) ## maximum length 254 char length

      ## we can check validation result for each field
      ## lets print to console
      echo "username " & v.fields["username"].msg & " -> " & $v.fields["username"].isValid
      echo "password " & v.fields["password"].msg & " -> " & $v.fields["password"].isValid

      ## set mustache context send data to template
      for fieldName, fieldData in v.fields:
        m.data[fieldName] = %fieldData

    @!Context.reply(Http200, m.render(tpl))

```

## 12. Template engine (Mustache)
Nim come with *Mustache* template engine. see katalis/plugins/nimMustache.nim, this template based on [https://github.com/soasme/nim-mustache](https://github.com/soasme/nim-mustache).

For using mustache, we need to import mustache from the plugins
```nim
import katalis/plugins/nimMustache.nim
```

For mustache specs, you can refer to [https://mustache.github.io/](https://mustache.github.io/)

Mustache can be inline or using *.mustache* file, in this case we will setup mustache using *.mustache*.

We need create *templates* directory
```bash
mkdir templates
```

Then add file *index.mustache, header.mustache, footer.mustache*. Mustache specs support partials template.

*header.mustache*
```mustache
<div>
  <h3>This is header section<h3>
</div>
```

*footer.mustache*
```mustache
<div>
  <h3>This is footer section<h3>
</div>
```

Then we will include partials *header.mustache and footer.mustache*

*index.mustache*
```mustache
<html>
  <head><title>mustache example</title></head>
  <body>
    <div>
      {{> header}}
      <div>
        <h3>This is content section<h3>
        <h3>{{post.title}}</h3>
        <p>{{post.article}}</p>
      </div>
      {{> footer}}
    </div>
  </body>
</html>
```

Mustache using *{{tag_mustache}}* for data binding, in current nim it support JsonNode, Tables, and mustache Context it self.

Let do with the code
```nim
@!App:
  @!Get "/test-mustache":
    let m = newMustache()
    m.data["post"] = %*{"title": "This is katalis", "article": "This is just simple micro framework but powerfull!"}
    ## call the index.mustache in the templates folder with m.render("index"mustacheawait @!Context.reply(Http200, m.render("index"))
```

## 13. Web Socket
Out of the box with webscoket. See *katalis/core/webSocket.nim*
```nim
@!App:
  ## it will accessed with ws://localhost:8000/ws
  @!WebSocket "/ws":
    if @!WebSocket.isOpen:
      if @!WebSocket.isRecvText:
        if not @!WebSocket.isRecvContinuation: ## \
          ## handle msg without continuation flag
          echo @!WebSocket.recvMsg ## \
          ## recieve message from client
          await @!WebSocket.replyText("This is from end point.") ## \
          ## send message to client

          ## for continuation text use
          ## await @!WebSocket.replyTextContinuation("data") ## \

          ## for send binary use
          ## await @!WebSocket.replyBinary("data")

          ## for send binary continuation use
          ## await @!WebSocket.replyBinaryContinuation("data")

        else: ## \
          ## handle msg with continuation flag
          echo @!WebSocket.recvMsg
          echo "handle with continuation message here"

      if @!WebSocket.isRecvBinary: ## \
        ## recv binary msg
        if not @!WebSocket.isRecvContinuation: ## \
          ## handle msg without continuation flag
          echo @!WebSocket.recvMsg

        else: ## \
          ## handle msg with continuation flag
          echo @!WebSocket.recvMsg
          echo "handle with continuation message here"

    if @!WebSocket.isClose:
      echo "Closed"
```

## 14. Serve SSL
Katalis also support serve SSL, we just need ssl certificate or we can use self signed certificate for development purpose.

Hot to create self signed SSL?, you can follow this instruction [https://devcenter.heroku.com/articles/ssl-certificate-self](https://devcenter.heroku.com/articles/ssl-certificate-self). Or you can find other resources from the internet world.

Then you can pass the certificate to the katalis settings
```nim
@!Settings.sslSettings = newSslSettings(
    certFile = "path to certificate",
    keyFile = "path to key file",
    port = Port(8443), ## default value
    enableVerify = false ## set to true if using production and valid ssl certificate
  )
```

it will server on [https://localhost:8443](https://localhost:8443)

## 15. Fullstack
Katalis is not fullstack framework, but if you want to use katalis as part of your stack you can use with others framework.

Frontend:
- [htmx](https://htmx.org)
- [karax](https://github.com/karaxnim/karax)
- [nimja](https://github.com/enthus1ast/nimja)

Databse (ORM):
- [norm](https://norm.nim.town/)
- [norman](https://norman.nim.town/)
- [katabase](https://github.com/zendbit/katabase)

## 16. Katalis Coding Style Guideline
Katalis coding style guideline is simple
- Follow nim lang Coding Style
- Only use Katalis DSL on the App and Pipeline don't use it on the *core, utils* to make katalis easy for debugging
