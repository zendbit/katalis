# katalis
Katalis is nim lang micro framework

## Install
```
nimble install katalis
```

## Running simple app
After installing katalis, you can simply create your first app by import *katalisApp*
```nim
import katalis/katalisApp
```

Katalis has some macros for it's own DSL. Katalis use *@!* as macros prefix (We will explore about katalis DSL on the next section).

Create nim source file, in this case we will use *app.nim*
```nim
import katalis/katalisApp

## lets do some basics configuration
@!Settings.enableReusePort = true
@!Settings.enableServeStatic = true
@!Settings.enableKeepAlive = true

## lets start simple app
@!App:
  @!Get "/":
    @!Context.reply(Http200, "<h1>Hello World!.</h1>")

## kick and start the app
@!Emit
```

Compile the source and run it!
```bash
nim c -r app.nim
```

Katalis will run on port 8000 as default port
```bash
Listening non secure (plain) on http://0.0.0.0:8000
```

Lets open browser and open [http://localhost:8000](http://localhost:8000)

![Alt http://localhost:8000](https://github.com/zendbit/katalis-readme-assets/blob/981946bf0fee5acaa341edc04ed3e26f82263e5c/Screenshot%20From%202024-11-03%2021-38-44.png)
## Katalis structure
## Configuration
## Serve static file
## Create routes and handling request
## Query string, form (urlencoded/multipart), json
## Validation
## Template engine (Mustache)
## Websocket
## SSL
## Create extensions
## Fullstack
