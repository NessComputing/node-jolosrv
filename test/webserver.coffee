rest = require 'restler'

Logger = require '../src/logger'
WebServer = require '../src/webserver'

describe 'WebServer', ->
  ws = null
  logger = Logger.get()

  url = "http://127.0.0.1:#{config.get('port')}"

  beforeEach (done) ->
    logger.clear()
    ws = new WebServer(config.get('port'))
    done()

  afterEach (done) ->
    ws.srv.close()
    done()

  it "should show the version info", (done) ->
    rest.get("#{url}/").on 'complete', (data) ->
      if (data instanceof Error) then assert.ifError data
      data.name.should.equal "jolosrv"
      assert.notEqual data.version, undefined
      done()

  it "should be able to add/update a client"

  it "should be able to return a list of clients"

  it "should be able to remove a client"

  it "should be able to add attributes to a client"

  it "should be able to remove attributes from a client"

  it "should be able to retrieve a detailed list of clients"
