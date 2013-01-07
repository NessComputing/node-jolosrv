Jolokia = require 'jolokia-client'
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
   * @param  {String}  (name) The name of the client to add
   * @param  {String}  (url) The jolokia url for the client
   * @param  {Object}  (attributes) The attributes to lookup for the client
   * @return {Object}  The jolokia client that was added
  ###
  add_client: (name, url, attributes) =>
    @jclients[name] =
      client: new Jolokia(url)
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
   * @param  {String} (name) The name of the client to remove
   * @return {String} The list of remaining clients
  ###
  remove_client: (name) =>
    delete @jclients[name]
    @list_clients()

  ###*
   * Returns detailed information for the given client.
   * @param  {String} (name) The name of the client to lookup
   * @return {Object} The hash representing the client info
  ###
  info_client: (name) =>
    client = @jclients[name]
    if client
      client['attributes']
    else
      null

  ###*
   * Generates a query information for the JMX update
  ###
  generate_query_info: (attributes) =>
    query_items = []
    unless attributes == null
      for m in attributes
        for attr in m.attributes
          if attr.hasOwnProperty('graph') then g = attr.graph else g = {}
          if attr.hasOwnProperty('composites') then c = attr.composites
          else c = []
          query_items.push
            mbean: m.mbean
            attribute: attr.name
            graph: g
            composites: c
      return query_items

  ###*
   * Generates a query array for the jolokia client
   * @param  {String} (name) The name of the client to query
   * @return {Array}  The list of items to query
  ###
  generate_client_query: (query_info) =>
    

  ###*
   *
  ###
  lookup_attribute_or_composites: (name) =>
    attrs = @info_client(name)

  ###*
   * Queries jolokia mbeans for a given client and updates their values.
   * @param {String} (name) The name of the client to query
   * @param {Function} (fn) The callback function
  ###
  query_jolokia: (name, fn) =>
    util = require 'util'
    attrs = @info_client(name)
    query_info = @generate_query_info(attrs)
    query = @generate_client_query(query_info)
    console.log util.inspect(query, true, 10)
    # if query == [] then return null
    query = []
    client = @jclients[name].client
    client.read query, (response) =>
      console.log response
      # console.log response
      fn(null, response.value)

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
  ###
  start_gmond: (host, port, spoof) =>
    return unless @interval
    if @gmond_interval_id then stop_gmond()
    @gmond_interval_id = setInterval () =>
      @submit_metrics()
    , @interval

  ###*
   * Stops the gmond metric spooler.
  ###
  stop_gmond: () =>
    if @gmond_interval_id
      clearInterval(@gmond_interval_id)
      @gmond_interval_id = null

  ###*
   * Submits gmetric data to the gmond target.
   * ex:  { host:  'exhost.domain.com',
   *        name:  'mygraphname',
   *        units: 'percentage', 
   *        type:  'int32',
   *        slope: 'both',
   *        tmax:   60,
   *        dmax:   120,
   *        group:  'mygraph_group' }
  ###
  submit_metrics: =>
    clients = @info_all_clients()

module.exports = JolokiaSrv
