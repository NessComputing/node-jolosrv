jolokia = require 'jolokia-client'

###*
 * Jolokia server client wrapper.
###
class JolokiaSrv
  constructor: (interval) ->
    @interval = interval || 10
    @jclients = {}

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
   * Add a new jolokia lookup client into the hash.
   * @param {String} (name) The name of the client
   * @param {String} (attr) The name of the attribute lookup
   * @param {Object} (data) The attribute lookup information
   * @return {Object} The added attribute
  ###
  add_attribute: (name, group, stat, attr, data) =>
    @jclients[name][group] or= new Object()
    @jclients[name][group][stat] or= new Object()
    @jclients[name][group][stat]['attributes'] or= new Array()

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
   * Add a new jolokia lookup client into the hash
  ###
  info_client: (name) =>
    @jclients[name]

  ###*
   * Starts up the ganglia gmond updater.
  ###
  start_gmond_service: =>

  ###*
   * Starts up the ganglia gmond updater.
  ###
  stop_gmond_service: =>

module.exports = JolokiaSrv
