gmetricsrv = require 'gmetric'

###*
 * Gmetric wrapper
###
class GmetricWrapper
  constructor: (@interval) ->
    @valid_counter_types = ['gauge, counter, derive, absolute']
    @gmetric = null
    @gmond_interval_id = null

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
      # BORKEN! Refs: https://github.com/jbuchbinder/node-gmetric/pull/2
      float: "front"
      front: "front"
      double: "double"

    name = value_lookup[name.toString().toLowerCase()]
    if name == undefined then name = "unknown"
    gmetricsrv["VALUE_#{name.toUpperCase()}"]

  ###*
   * Sets up the gmond metric spooler.
   * @param {String} (host) The target gmond host
   * @param {String} (port) The target gmond port
   * @param {String} (spoof) The spoofed hostname to act as
  ###
  setup_gmond: (host, port, spoof) =>
    @gmetric = new gmetricsrv()
    @gmetric.gmetric(host, port, spoof)
    return unless @interval
    @gmond_interval_id = setInterval () =>
      if @gmetric
        # TODO: Finish sendMetric
        @gmetric.sendMetric()
    , @interval

  ###*
   * Stops the gmond metric spooler.
  ###
  stop_gmond: () =>
    if @gmond_interval_id then clearInterval(@gmond_interval_id)

module.exports = GmetricWrapper
