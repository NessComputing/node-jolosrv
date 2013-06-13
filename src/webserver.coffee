express = require 'express'
http = require 'http'
require('pkginfo')(module, 'name', 'version')

config = require 'nconf'
logger = require './logger'
{identity, generate_identity} = require './identity'
JolokiaSrv = require './jolokiasrv'

###*
 * The webserver class.
###
class WebServer
  constructor: ->
    @jsrv = new JolokiaSrv()
    @app = express()

    @app.use express.bodyParser()
    @app.use @errorHandler
    @app.use express.favicon()
    @setup_routing()
    @srv = http.createServer(@app)
    @srv.listen(config.get('port'))
    logger.info "Webserver is up at: http://0.0.0.0:#{config.get('port')}"

  errorHandler: (err, req, res, next) ->
    res.status 500
    res.render 'error', error: err

  # Sets up the webserver routing.
  setup_routing: =>

    # Returns the base name and version of the app.
    @app.get '/', (req, res, next) =>
      res.json 200, 
        name: exports.name,
        version: exports.version

    # List all of the current clients. (Details if info=true)
    @app.get '/clients', (req, res, next) =>
      if "info" in Object.keys(req.query) and req.query.info == 'true'
        res.json 200,
          clients: @jsrv.info_all_clients()
      else
        res.json 200,
          clients: @jsrv.list_clients()

    # Add/update a client.
    @app.post '/clients', (req, res, next) =>
      client = req.body
      unless client.name then return res.json 400,
        error: "Adding or updating a client requires a name."
      unless client.url then return res.json 400,
        error: "Adding or updating a client requires a jolokia url."

      console.log client

      cl = @jsrv.add_client(
        client.name, client.url, client.template, client.cluster)
      res.json 200,
        name: client.name
        cluster: client.cluster
        url: client.url
        template: cl.template

    # Get details for a given client.
    @app.get '/clients/:client', (req, res, next) =>
      client = req.params.client
      data = @jsrv.info_client(client)
      if data == null or data == undefined
        return res.json 404, message: "Client does not exist."
      res.json 200, data

    # Delete a client.
    @app.del '/clients/:client', (req, res, next) =>
      res.json 200,
        clients: @jsrv.remove_client(req.params.client)

    # Get a list of templates
    @app.get '/templates', (req, res, next) =>
      res.json 200,
        templates: @jsrv.list_templates()

    # Get information for a given template
    @app.get '/templates/:template', (req, res, next) =>
      template_info = @jsrv.templates[req.params.template]
      if template_info
        res.json 200, template_info
      else
        res.json 404, error: "The requested template doesn't exist"

module.exports = WebServer
