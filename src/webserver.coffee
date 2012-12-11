express = require 'express'
http = require 'http'
require('pkginfo')(module, 'name', 'version')

Config = require './config'
Logger = require './logger'
{Identity, generate_identity} = require './identity'
JolokiaSrv = require './jolokiasrv'

###*
 * The iOS-ota webserver class.
###
class WebServer
  constructor: ->
    @config = Config.get()
    @logger = Logger.get()
    @identity = Identity.get()
    @jsrv = new JolokiaSrv()
    @app = express()

    @app.use express.bodyParser()
    @app.use @errorHandler
    @setup_routing()
    @srv = http.createServer(@app)
    @srv.listen(@config.get('port'))
    @logger.info "Webserver is up at: http://0.0.0.0:#{@config.get('port')}"

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

    # Silence favicon requests.
    @app.get '/favicon.ico', (req, res, next) =>
      res.json 404, "No favicon exists."

    # List all of the current clients.
    @app.get '/clients', (req, res, next) =>
      res.json 200,
        clients: @jsrv.list_clients()

    # Add/update a client.
    @app.post '/clients', (req, res, next) =>
      client = req.body
      unless client.name then return res.json 400,
        error: "Adding or updating a client requires a name."
      unless client.url then return res.json 400,
        error: "Adding or updating a client requires a jolokia url."

      cl = @jsrv.add_client(client.name, client.url, client.attributes)
      res.json 200,
        name: client.name
        url: client.url
        attributes: cl.attributes

    # Delete a client.
    @app.del '/clients/:client', (req, res, next) =>
      res.json 200,
        deleted: req.params.client

module.exports = WebServer
