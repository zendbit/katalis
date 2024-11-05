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

## 3. Katalis structure
in progress

## 4. Configuration
in progress

## 5. Serve static file
in progress

## 6. Create routes and handling request
in progress

## 7. Katalis DSL (Domain Specific Language)

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
