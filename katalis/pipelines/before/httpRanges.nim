##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## parse ranges request
## Range: bytes=0-1000, 2000-3000
## see HTTP Ranges (accept-ranges)
##


import std/
[
  options
]


import
  ../../core/routes,
  ../../macros/sugar,
  ../../core/environment


@!App:
  @!Before:
    # parse range request to HttpContext.ranges
    # seq[tuple(start: BiggestInt, stop: BiggestInt)]
    # parse range request
    # Range: bytes=0-1023, 2000-3000
    # Range: bytes=-500
    # Range: bytes=6000-
    # Range: 0-0, -1
    # see rfc about http ranges
    if not @!Env.settings.enableRanges:
      @!Res.headers["accept-ranges"] = "none"

    else:
      @!Res.headers["accept-ranges"] ="bytes"
      @!Req.ranges = @[]
      for rangesHeader in
        @!Req.
          headers.
          getValues("range"):

        for ranges in rangesHeader.
          replace("bytes=", "").
          strip.
          split(","):

          if ranges.strip == "": continue

          var start, stop: Option[BiggestInt]

          if ranges.startsWith("-"):
            # parse bytes=-500
            start = some(ranges.strip.parseBiggestInt)

          elif ranges.endsWith("-"):
            # parse bytes=6000-
            start = some(ranges.strip.replace("-", "").parseBiggestInt)

          else:
            # parse bytes=0-500
            let rangeValues = ranges.split("-")
            if rangeValues.len == 2:
              start = some(rangeValues[0].strip.parseBiggestInt)
              stop = some(rangeValues[1].strip.parseBiggestInt)

          @!Req.ranges.add((start, stop))

