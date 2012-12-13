jolokia = require 'jolokia-client'
async = require 'async'

Config = require './config'
gwrapper = require './gmetric_wrapper'

###*
 * Jolokia server client wrapper.
###
class JolokiaSrv
  constructor: (@interval) ->
    @interval or= 10
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
      gw: new gwrapper(@config.get('gmetric'), @config.get('gPort'), true)

  ###*
   * Add a new jolokia lookup client into the hash.
   * @param {String} (name) The name of the client
   * @param {String} (attr) The name of the attribute lookup
   * @param {Object} (data) The attribute lookup information
   * @return {Object} The added attribute
  ###
  add_attribute: (name, component, group, attr, data) =>
    @jclients[name] or= new Object()
    @jclients[name][component] or= new Object()
    @jclients[name][component][group] or= new Object()
    @jclients[name][component][group][attr] = data || new Object()

  ###*
   * Removes all jolokia attributes for the given client group
   * @param {String} (name) The name of the client to remove attributes of
   * @param {String} (group) The name of the group to remove attributes of
  ###
  remove_attributes: (name, group) =>
    return unless @jclients[name]
    return unless @jclients[name][group]
    delete @jclients[name][group]

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
    @jclients[name]

  ###*
   * Returns detailed information for all clients.
   * @return {Object} The hash representing the all client info
  ###
  info_all_clients: () =>
    keys = Object.keys(@jclients)
    # async.map

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
