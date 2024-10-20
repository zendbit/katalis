##
## katalis framework
## This framework if free to use and to modify
## License: MIT
## Author: Amru Rosyada
## Email: amru.rosyada@gmail.com, amru.rosyada@amscloud.co.id
## Git: https://github.com/zendbit/katalis
##

##
## encryption tools
##

proc xorEncodeDecode*(
  data: string,
  key: string
): string = ##\
## XOR encode decode with given data and key
  
  # xor encode decode the data with given key
  var decodedData = ""
  for i in 0..<data.len:
    decodedData &= chr(data[i].uint8 xor key[i mod 4].uint8)

  decodedData