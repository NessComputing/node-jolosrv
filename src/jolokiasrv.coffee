jolokia = require 'jolokia-client'

###*
 * Jolokia server client wrapper.
###
class JolokiaSrv
  constructor: (interval) ->
    @interval = interval || 10
    @jclients = {}
    @add_client('test', 'http://10.29.62.32:8083/jolokia/')
    @jclients['test'].read 'java.lang:name=Par Survivor Space,type=MemoryPool', (response) ->
      # console.log Object.keys(response.value)
      console.log response.value

  add_client: (name, url) =>
    # url = 'http://10.29.62.32:8083/jolokia/'
    @jclients[name] = new jolokia(url)

module.exports = JolokiaSrv
