gmetricsrv = require 'gmetric'

###*
 * Gmetric wrapper
###
class GmetricWrapper
  constructor: (host, port, spoof) ->
    @counter_types = ['gauge, counter, derive, absolute']
    @typestrings = ['string', 'uint16', 'int16', 
                    'uint32', 'int32', 'float', 'double']
    @gmetric = null
    @configure_gmetric(host, port, spoof)

  ###*
   * Returns the integer lookup for the given slope type for gmetric.
   * @param {String} (name) The name of the slope type
   * @return {Integer} The integer representation of the name lookup
  ###
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
    gmetricsrv["SLOPE_#{name.toUpperCase()}"]

  ###*
   * Returns the integer lookup for the given data type for gmetric.
   * @param {String} (name) The name of the data type
   * @return {Integer} The integer representation of the name lookup
  ###
  value_type: (name) =>
    value_lookup =
      string: "string"
      ushrt: "unsigned_short"
      ushort: "unsigned_short"
      unsigned_short: "unsigned_short"
      uint16: "unsigned_short"
      short: "short"
      shrt: "short"
      int16: "short"
      uint: "unsigned_int"
      uint32: "unsigned_int"
      int: "int"
      int32: "int"
      float: "float"
      double: "double"

    name = value_lookup[name.toString().toLowerCase()]
    if name == undefined then name = "unknown"
    gmetricsrv["VALUE_#{name.toUpperCase()}"]

  ###*
   * Configures the gmetric service object.
   * @param {String} (host) The target gmond host
   * @param {String} (port) The target gmond port
   * @param {String} (spoof) 
   * @return {Object} The configured gmetric object
  ###
  configure_gmetric: (host, port, spoof) =>
    if host and port and spoof
      @gmetric = gmetricsrv.gmetric(host, port, spoof)

module.exports = GmetricWrapper
