gmetriclib = require 'gmetric'

###*
 * Gmetric wrapper
###
class GmetricWrapper
  constructor: () ->
    @valid_counter_types = ['gauge, counter, derive, absolute']

  slope: (name) =>
    value_lookup =
      '0': "zero"
      none: "zero"
      zero: "zero"
      positive: "positive"
      '1': "positive"
      negative: "negative"
      '-1': "negative"
      both: "both"

    name = value_lookup[name.toString().toLowerCase()]
    if name == undefined then name = "unspecified"
    gmetriclib["SLOPE_#{name.toUpperCase()}"]

  value_type: (name) =>
    value_lookup =
      string: "string"
      ushrt: "unsigned_short"
      ushort: "unsigned_short"
      unsigned_short: "unsigned_short"
      short: "short"
      shrt: "shrt"
      uint: "unsigned_int"
      int: "int"
      float: "float"
      double: "double"

    name = value_lookup[name.toString().toLowerCase()]
    if name == undefined then name = "unknown"
    gmetriclib["VALUE_#{name.toUpperCase()}"]

module.exports = GmetricWrapper
