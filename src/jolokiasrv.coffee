os = require 'os'
fs = require 'fs'
path = require 'path'
util = require 'util'

Jolokia = require 'jolokia-client'
async = require 'async'
mkdirp = require 'mkdirp'
Gmetric = require 'gmetric'

Config = require './config'
Logger = require './logger'

###*
 * Jolokia server client wrapper.
###
class JolokiaSrv
  constructor: (@interval=20) ->
    @jclients  = new Object()
    @templates = new Object()

    @gmond_interval_id = null
    @gmetric = new Gmetric()
    @config = Config.get()
    @logger = Logger.get()

    @setup_template_dir()

  ###*
   * Sets up the template directory and loads the current templates
  ###
  setup_template_dir: =>
    mkdirp @config.get('template_dir'), (err) =>
      if (err)
        @logger.error "Error creating template directory: #{err}"
        process.exit(1)
      else
        @watch_templates()

  ###*
   * Watch template directory and update @templates on changes.
   * @note watching with inotify is current only supported on linux,
   * other operating systems will drop to an initial-load only.
  ###
  watch_templates: =>
    @load_all_templates (err) =>
      if os.platform() == 'linux'
        fs.watch @config.get('template_dir')
        , (event, filename) =>
          fs.exists path.resolve(@config.get('template_dir'), filename)
          , (exists) =>
            if exists
              @load_template(filename)
            else
              @unload_template(filename)

  ###*
   * Loads all of the current templates in the template directory.
   * @param {Function} (fn) The callback function
  ###
  load_all_templates: (fn) =>
    @stop_gmond()
    fs.readdir path.resolve(@config.get('template_dir')), (err, files) =>
      if files == undefined
        json_files = []
      else
        json_files = files.filter (x) -> x.match /\.json/
      async.each json_files, @load_template, (err) =>
        @start_gmond()
        unless fn == undefined then fn(err)

  ###*
   * Removes the given template from the available templates.
   * @param {String}   (template) The template to remove
  ###
  load_template: (template, fn) =>
    fs.readFile path.resolve(@config.get('template_dir'), template)
      , 'utf8', (err, data) =>
        if (err)
          @logger.error "Error reading file: #{template}: #{err}"
        else
          try
            json_data = JSON.parse(data)
            @templates[json_data.name] =
              inherits: json_data.inherits
              mappings: json_data.mappings
          catch error
            @logger.error "Error parsing `#{template}`: #{error}"
        unless fn == undefined then fn(err)

  ###*
   * Removes the given template from the available templates.
   * @param {String} (template) The template to remove
  ###
  unload_template: (template) =>
    delete @templates[template]

  ###*
   * The list of current templates.
   * @return {Array} The current list of templates
  ###
  list_templates: =>
    Object.keys(@templates)

  ###*
   * Add a new jolokia lookup client into the hash.
   * @param  {String} (name) The name of the client to add
   * @param  {String} (url) The jolokia url for the client
   * @param  {Object} (template) The attributes template
   * @param  {Object} (cluster) The cluster for the client
   * @return {Object} The jolokia client that was added
  ###
  add_client: (name, url, template, cluster) =>
    @jclients[name] =
      client: new Jolokia(url)
      name: name
      cluster: cluster
      url: url
      template: template
      cache: new Object()

  ###*
   * Cleanup mappings for a client before they are cached for fast lookups.
   * @param {Object} (mappings) The metrics mappings for a given client
   * @param {Function} (fn) The callback function
  ###
  convert_mappings_to_hash: (mappings, fn) =>
    async.reduce mappings, new Object()
    , (mbean_memo, mbean_attr, mbean_cb) =>
      mbean_memo[mbean_attr.mbean] ||= new Object()

      # Handle Attributes
      async.reduce mbean_attr.attributes, mbean_memo[mbean_attr.mbean]
      , (a_memo, a_attr, a_cb) =>
        a_memo[a_attr.name] ||= new Object()
        if a_attr.hasOwnProperty('graph') and
        Object.keys(a_attr.graph).length > 0
          a_memo[a_attr.name].graph = a_attr.graph

        if a_attr.hasOwnProperty('value')
          a_memo[a_attr.name].value = a_attr.value

        # Handle composites
        if a_attr.hasOwnProperty('composites') and
        a_attr.composites.length > 0
          async.each a_attr.composites
          , (cmp_attr, cmp_cb) =>
            a_memo[a_attr.name][cmp_attr.name] ||= new Object()
            if cmp_attr.hasOwnProperty('graph') and
            Object.keys(cmp_attr.graph).length > 0
              a_memo[a_attr.name][cmp_attr.name].graph = cmp_attr.graph

            if cmp_attr.hasOwnProperty('value')
              a_memo[a_attr.name][cmp_attr.name].value = cmp_attr.value
            cmp_cb(null)
          , (cmp_err) =>
            a_cb(null, a_memo)
        else
          a_cb(null, a_memo)

      , (a_err, a_results) =>
        mbean_cb(a_err, mbean_memo)

    , (err, results) =>
      fn(err, results)

  ###*
   * List the current jolokia clients.
   * @return {Array} The list of current clients
  ###
  list_clients: =>
    Object.keys(@jclients)

  ###*
   * Removes a jolokia client from the hash.
   * @param  {String} (name) The name of the client to remove
  ###
  remove_client: (name) =>
    delete @jclients[name]

  ###*
   * Returns detailed information for the given client.
   * @param  {String} (name) The name of the client to lookup
   * @return {Object} The hash representing the client info
  ###
  info_client: (name) =>
    client = @jclients[name]
    if client
      if client.template
        @generate_template_info(client.template)
      else
        {}
    else
      null

  ###*
   * Sort mbean entries to handle jolokia silliness.
   * @param  {String} (mbean) The mbean name to sort
   * @return {String} The sorted mbean string
  ###
  sort_mbean: (mbean) =>
    minfo = mbean.split(':')
    suffix = minfo.pop()
    minfo.push(suffix.split(',').sort().join(','))
    minfo.join(':')

  ###*
   * Merges the parent template with the current template.
   * @param  {String} (template) The template to merge
   * @return {Object} The merged template
  ###
  merge_parent_templates: (template) =>
    mappings = @templates[template].mappings
    inherits = @templates[template].inherits
    if inherits == null or inherits == undefined
      return mappings
    else
      return @merge_mappings(
        @merge_parent_templates(inherits), mappings)

  ###*
   * Extends a base mapping with the given extension
   * @param  {Array} (base) The base template mapping
   * @param  {Array} (extension) The extension mapping
   * @return {Array} The merged extension mapping
  ###
  merge_mappings: (base, extension) =>
    if base == undefined
      return extension
    if extension == undefined
      return base

    merged_map = []
    base_mappings = base.map (X) -> X.mbean
    extension_mappings = extension.map (X) -> X.mbean

    extension_only = extension_mappings.filter (X) ->
      X not in base_mappings

    base_only = base_mappings.filter (X) ->
      X not in extension_mappings

    merge_objs = new Object()
    base_mappings.concat(extension_mappings).forEach (X) ->
      if merge_objs.hasOwnProperty(X)
        merge_objs[X] += 1
      else
        merge_objs[X] = 1

    merged_map = merged_map.concat(base.filter (X) ->
      X.mbean in base_only)
    merged_map = merged_map.concat(extension.filter (X) ->
      X.mbean in extension_only)

    merges = Object.keys(merge_objs).filter (X) -> merge_objs[X] > 1
    for m in merges
      bmerge = (base.filter (X) -> X.mbean == m).pop()
      emerge = (extension.filter (X) -> X.mbean == m).pop()
      bmerge.attributes = @merge_attributes_or_composites(
        bmerge.attributes, emerge.attributes)

      merged_map.push bmerge
    merged_map

  ###*
   * Extends a base attribute/composite with given extensions.
   * @param  {Array} (base) The base composite array
   * @param  {Array} (extension) The extended composite array
   * @return {Array} The merged composite array
  ###
  merge_attributes_or_composites: (base, extension) =>
    if extension == null or extension == undefined
      return base
    if base == null or base == undefined
      return extension
    merged_map = []
    base_composites = base.map (X) -> X.name
    extension_composites = extension.map (X) -> X.name

    extension_only = extension_composites.filter (X) ->
      X not in base_composites

    base_only = base_composites.filter (X) ->
      X not in extension_composites

    merge_objs = new Object()
    base_composites.concat(extension_composites).forEach (X) ->
      if merge_objs.hasOwnProperty(X)
        merge_objs[X] += 1
      else
        merge_objs[X] = 1

    merged_map = merged_map.concat(base.filter (X) ->
      X.name in base_only)
    merged_map = merged_map.concat(extension.filter (X) ->
      X.name in extension_only)

    merges = Object.keys(merge_objs).filter (X) -> merge_objs[X] > 1
    for m in merges
      bmerge = (base.filter (X) -> X.name == m).pop()
      emerge = (extension.filter (X) -> X.name == m).pop()
      if emerge.hasOwnProperty('graph')
        for k in Object.keys(emerge.graph)
          bmerge.graph[k] = emerge.graph[k]

      if emerge.hasOwnProperty('composites')
        if bmerge.hasOwnProperty('composites')
          bmerge.composites = @merge_attributes_or_composites(
            bmerge.composites, emerge.composites)
        else
          bmerge.composites = emerge.composites

      merged_map.push bmerge
    merged_map

  ###*
   * Generates the information for a given template including parents.
   * @param  {String} (template) The template to generate information for
   * @return {Object} The merged information for a given template
  ###
  generate_template_info: (template) =>
    if @templates[template] == undefined then return @templates[template]
    if @templates[template].inherits == null \
    or @templates[template].inherits == undefined
      @templates[template].inherits = null

    if @templates[template].inherits != undefined
      { mappings: @merge_parent_templates(template) }
    else
      delete @templates[template].inherits
      @templates[template]

  ###*
   * Generates a query information for the JMX update.
   * @param  {Object} (mappings) The detailed information for a client
   * @return {Array}  The list of info objects
  ###
  generate_query_info: (client) =>
    query_info = []
    unless client.mappings == null
      for m in client.mappings
        for attr in m.attributes
          if attr.hasOwnProperty('graph') then g = attr.graph else g = {}
          if attr.hasOwnProperty('composites') then c = attr.composites
          else c = []
          query_info.push
            mbean: @sort_mbean(m.mbean)
            attribute: attr.name
            graph: g
            composites: c
      return query_info

  ###*
   * Generates a query array for the jolokia client.
   * @param  {Object} (query_info) The query info for a client
   * @return {Array}  The list of items to query
  ###
  generate_client_query: (query_info) =>
    query = []
    for q in query_info
      query.push({ mbean: @sort_mbean(q.mbean), attribute: q.attribute })
    return query

  ###*
   * Takes the query_info and response objects and gets the proper result set.
   * @param {String} (name) The name of the client to query
   * @param {Object} (mappings) The metrics mappings for a client
   * @param {Object} (response) The query response from jolokia
   * @param {Function} (fn) The callback function
  ###
  lookup_attribute_or_composites: (name, mappings, response, fn) =>
    @convert_mappings_to_hash mappings, (h_err, hattribs) =>
      handle_response_obj = (item, cb) =>
        mbean = @sort_mbean(item.request.mbean)
        attribute = item.request.attribute
        value = item.value

        retrieve_composite_value = (input) =>
          if typeof input == 'string'
            input = input.split('|')
          return recursive_get_val(value, input)

        recursive_get_val = (walk, list) =>
          if list.length > 1
            next = list.shift()
            return recursive_get_val(walk[next], list)
          else
            return walk[list]

        # Add the top-level value if it is a simple k/v
        try
          if hattribs[mbean][attribute].hasOwnProperty('graph') and
          Object.keys(hattribs[mbean][attribute].graph).length > 0
            hattribs[mbean][attribute].value = value
        catch error
          @logger.error """
          Error parsing attribute: #{error}
          mbean: #{mbean}
          attribute: #{attribute}

          jolokia_hash: #{util.inspect(hattribs, true, 10)}
          """

        # For each key that isn't graph or value, get their values
        keys = (k for k in Object.keys(hattribs[mbean][attribute]) when \
        k != 'graph' and k!= 'value')
        for k in keys
          try
            hattribs[mbean][attribute][k].value = retrieve_composite_value(k)
          catch error
            @logger.error """
            Error parsing composite attribute: #{error}
            mbean: #{mbean}
            attribute: #{attribute}
            composite: #{k}

            jolokia_hash: #{util.inspect(hattribs, true, 10)}
            """
        cb(null)

      async.each response, handle_response_obj, (err) =>
        @jclients[name].cache = hattribs
        fn(null, hattribs)

  ###*
   * Queries jolokia mbeans for a given client and updates their values.
   * @param {String} (name) The name of the client to query
   * @param {Function} (fn) The callback function
  ###
  query_jolokia: (name, fn) =>
    cinfo = @info_client(name)
    query_info = @generate_query_info(cinfo)
    query = @generate_client_query(query_info)
    if query == [] then return null
    client = @jclients[name].client
    client.read query, (response) =>
      @lookup_attribute_or_composites(name, cinfo.mappings, response, fn)

  ###*
   * Attempt to query each of the nodes, ignoring failures.
  ###
  query_all_jolokia_nodes: (cb) =>
    attempt_to_query = (client, fn) =>
      try
        @query_jolokia client, (err, attribs) =>
          fn(null)
      catch error
        fn(error)

    client_list = Object.keys(@jclients)
    if client_list.length > 0
      async.each client_list, attempt_to_query, (err) =>
        if cb then cb(null)
    else
      if cb then cb(null)

  ###*
   * Returns detailed information for all clients.
   * @return {Object} The hash representing the all client info
  ###
  info_all_clients: =>
    clients = new Object()
    for key in Object.keys(@jclients)
      clients[key] = @info_client(key)
    clients

  ###*
   * Starts up the gmond metric spooler.
  ###
  start_gmond: =>
    return unless @interval
    if @gmond_interval_id then @stop_gmond()
    @gmond_interval_id = setInterval () =>
      @query_all_jolokia_nodes()
      @submit_metrics()
    , (@interval * 1000)

  ###*
   * Stops the gmond metric spooler.
  ###
  stop_gmond: =>
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
   *        group:  'mygraph_group',
   *        cluster: 'example_cluster' }
  ###
  submit_metrics: =>
    clientlist = Object.keys(@jclients)
    unless clientlist.length > 0 then return

    # recursive_walk
    walk_graphs = (client, cache, cluster) =>
      if Object.keys(@jclients[client]) == 0
        return

      for mbean in Object.keys(cache)
        mbean = @sort_mbean(mbean)
        for attrib in Object.keys(cache[mbean])
          ainfo = cache[mbean][attrib]
          if a == undefined
            return
          if ainfo.hasOwnProperty('graph') and ainfo.hasOwnProperty('value')
            compile_and_submit_metric(
              client, ainfo.graph, ainfo.value, cluster)

          for comp in Object.keys(cache[mbean][attrib])
            c = cache[mbean][attrib][comp]
            if c == undefined
              return
            if c.hasOwnProperty('graph') and c.hasOwnProperty('value')
              compile_and_submit_metric(
                client, c.graph, c.value, cluster)

    # create gmetric data and submit
    compile_and_submit_metric = (client, graph, value, cluster) =>
      metric = graph
      metric.value = value

      if cluster == null or cluster == undefined
        metric.cluster = @config.get('cluster')
      else
        metric.cluster = cluster
      cluster = [@config.get('cluster_prefix'), metric.cluster].filter (x) ->
        x != null and x != undefined

      metric.cluster = cluster.join('_')
      metric.hostname = client
      metric.spoof = true
      metric.spoof_host = client
      if metric.value == undefined then metric.value = 0
      if metric.type == undefined then metric.type = 'int32'
      if metric.slope == undefined then metric.slope = 'both'
      @gmetric.send(@config.get('gmetric'), @config.get('gPort'), metric)

    async.each clientlist
    , (client, cb) =>
      walk_graphs(client, @jclients[client].cache, @jclients[client].cluster)
    , (err) =>
      @logger.error "Error submitting metrics: #{err}"

module.exports = JolokiaSrv
