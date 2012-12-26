jolokia = require 'jolokia-client'
async = require 'async'
Gmetric = require 'gmetric'

Config = require './config'

###*
 * Jolokia server client wrapper.
###
class JolokiaSrv
  constructor: (@interval) ->
    @interval or= 15
    @jclients = new Object()
    @gmond_interval_id = null
    @config = Config.get()

  ###*
   * Add a new jolokia lookup client into the hash.
   * @param {String} (name) The name of the client to add
   * @param {String} (url) The jolokia url for the client
   * @param {Object} (attributes) The attributes to lookup for the client
   * @return {Object} The jolokia client that was added
  ###
  add_client: (name, url, attributes) =>
    @jclients[name] =
      client: new jolokia(url)
      attributes: attributes || new Object()

  ###*
   * Removes all jolokia attributes for the given client.
   * @param {String} (name) The name of the client to remove attributes of
  ###
  remove_attributes: (name) =>
    return unless @jclients[name]
    return unless Object.keys(@jclients[name]['attributes']).length > 0
    for key in Object.keys(@jclients[name]['attributes'])
      delete @jclients[name]['attributes'][key]

  ###*
   * List the current jolokia clients.
   * @return {Array} The list of current clients
  ###
  list_clients: =>
    Object.keys(@jclients)

  ###*
   * Removes a jolokia client from the hash.
   * @param {String} (name) The name of the client to remove
   * @return {String} The list of remaining clients
  ###
  remove_client: (name) =>
    delete @jclients[name]
    @list_clients()

  ###*
   * Returns detailed information for the given client.
   * @param {String} (name) The name of the client to lookup
   * @return {Object} The hash representing the client info
  ###
  info_client: (name) =>
    client = @jclients[name]
    if client
      client['attributes']
    else
      null

  ###*
   * Returns detailed information for all clients.
   * @return {Object} The hash representing the all client info
  ###
  info_all_clients: () =>
    clients = new Object()
    for key in Object.keys(@jclients)
      clients[key] = @info_client(key)
    clients

  ###*
   * Starts up the gmond metric spooler.
   * @param {String} (host) The target gmond host
   * @param {String} (port) The target gmond port
   * @param {Boolean} (spoof) Whether or not the hostname is spoofed
  ###
  start_gmond: (host, port, spoof) =>
    @gmetric = new gmetricsrv()
    @gmetric.gmetric(host, port, spoof)
    return unless @interval
    @gmond_interval_id = setInterval () =>
      @submit_metrics()
    , @interval

  ###*
   * Stops the gmond metric spooler.
  ###
  stop_gmond: () =>
    if @gmond_interval_id then clearInterval(@gmond_interval_id)

  ###*
   * Submits gmetric data to the gmond target.
   * @param {Object} (ginfo) Where ginfo is the following:
   * ex:  { host:  'exhost.domain.com',
   *        name:  'mygraphname',
   *        units: 'percentage', 
   *        type:  'int',
   *        slope: 'both',
   *        tmax:   60,
   *        dmax:   120,
   *        group:  'mygraph_group' }
  ###
  submit_metrics: (ginfo, value) =>
    ginfo['tmax'] or= 60
    ginfo['dmax'] or= 120
    if @gmetric
      # TODO: Finish sendMetric
      @gmetric.sendMetric()

module.exports = JolokiaSrv
