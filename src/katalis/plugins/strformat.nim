import std/[strutils, unicode, strformat]
export strformat


proc localizedCurrency*(
    amount: string,
    decimalSep: char = '.',
    thousandSep: char = ','
  ): string = ## \
  ## localized currencies
  ##
  ## localizedCurrency(123456789) # US-style: 123,456,789
  ## localizedCurrency(123456789, ",", ".")  # European-style: 123.456.789
  ##

  let amountParts = amount.split(decimalSep)
  let length = amountParts[0].len
  for i in countdown(length - 1, 0):
    if i != length-1 and (length - i - 1) mod 3 == 0:
      result.add($thousandSep)
    result.add(amountParts[0][i])
  result = reversed(result)
  if amountParts.len == 2:
    result = result & $decimalSep & amountParts[1]
