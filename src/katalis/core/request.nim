##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## Request type implementation
##


import
  std/[
    httpcore,
    tables,
    json,
    xmltree,
    options
  ]
## std import

export
  httpcore,
  tables,
  json,
  xmltree,
  options
## std export


import uri3
## nimble

export uri3
## nimble


import form
export form


type
  Request* = ref object of RootObj ## \
    ## Request object type

    httpVersion*: string  ## \
    ## contains request header from client
    httpMethod*: HttpMethod ## \
    ## request http method from client
    uri*: Uri3 ## \
    ## contains uri object from client
    ## read uri3 nimble package
    headers*: HttpHeaders ## \
    ## contains request headers from client
    body*: string ## \
    ## contains request body from client
    param*: RequestParam ## \
    ## request parameter
    isStaticfile*: bool ## \
    ## hold if request is static file or not
    ## this will set on route process


  RequestParam* = ref object of RootObj ## \
    ## request parameter object

    segment*: TableRef[string, string] ## \
    ## hold retrieved parameter segment
    ## match again route
    ## ex /profile/:id/details/:address
    ## match with /profile/123/details/colorado
    ## if match will contains pair id => 123, address => colorado
    query*: TableRef[string, string] ## \
    ## hold retrieved query string
    ## match again route
    ## ex /profile?id=100&address=colorado
    ## match with /profile then will retrieve the query string
    ## if match will contains pair id => 100, address => colorado
    json*: JsonNode ## \
    ## hold json request param
    xml*: XmlNode ## \
    ## hold xml request param
    form*: Form ## \
    ## hold form request param


proc newRequest*(
    httpMethod: HttpMethod = HttpGet,
    httpVersion: string = constants.HttpVersion,
    uri: Uri3 = parseUri3(""),
    headers: HttpHeaders = newHttpHeaders(),
    body: string = ""
  ): Request {.gcsafe.} =
  ## create new request
  ## in general this will return Request instance with default value
  ## and will be valued with request from client

  Request(
    httpMethod: httpMethod,
    httpVersion: httpVersion,
    uri: uri,
    headers: headers,
    body: body,
    param: RequestParam(
        segment: newTable[string, string](),
        query: newTable[string, string](),
        json: JsonNode(),
        xml: XmlNode(),
        form: newForm()
      )
  )
