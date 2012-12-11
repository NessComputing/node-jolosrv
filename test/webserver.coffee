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
      data.name.should.equal "jolosrv"
      assert.notEqual data.version, undefined
      done()

  it "should be able to add a client", (done) ->
    rest.post("#{url}/clients",
      data:
        name: "bob"
        url: "http://localhost:1234"
    ).on 'complete', (data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234'
      Object.keys(data.attributes).length.should.equal 0
      done()

  it "throws 400 when adding a client without a name", (done) ->
    rest.post("#{url}/clients",
      data:
        url: "http://localhost:1234"
    ).on 'complete', (data, res) =>
      res.statusCode.should.equal 400
      done()

  it "throws 400 when adding a client without a url", (done) ->
    rest.post("#{url}/clients",
      data:
        name: "bob"
    ).on 'complete', (data, res) =>
      res.statusCode.should.equal 400
      done()

  it "should be able to update a client", (done) ->
    rest.post("#{url}/clients",
      data:
        name: "bob"
        url: "http://localhost:1234"
    ).on 'complete', (data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234'
      Object.keys(data.attributes).length.should.equal 0

      rest.post("#{url}/clients",
        data:
          name: "bob"
          url: "http://localhost:1235"
      ).on 'complete', (data) =>
        data.name.should.equal 'bob'
        data.url.should.equal 'http://localhost:1235'
        Object.keys(data.attributes).length.should.equal 0
        done()

  it "should be able to return a list of clients", (done) ->
    rest.post("#{url}/clients",
      data:
        name: "bob"
        url: "http://localhost:1234"
    ).on 'complete', (data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234'
      Object.keys(data.attributes).length.should.equal 0
      rest.get("#{url}/clients").on 'complete', (data) =>
        data.clients.should.include 'bob'
        Object.keys(data.clients).length.should.equal 1
        done()

  it "should be able to remove a client", (done) ->
    rest.post("#{url}/clients",
      data:
        name: "bob"
        url: "http://localhost:1234"
    ).on 'complete', (data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234'
      
      rest.get("#{url}/clients").on 'complete', (data) =>
        data.clients.should.include 'bob'
        Object.keys(data.clients).length.should.equal 1

        rest.post("#{url}/clients",
          data:
            name: "joe"
            url: "http://localhost:1235"
        ).on 'complete', (data) =>
          data.name.should.equal 'joe'
          data.url.should.equal 'http://localhost:1235'

          rest.get("#{url}/clients").on 'complete', (data) =>
            data.clients.should.include 'bob'
            data.clients.should.include 'joe'
            Object.keys(data.clients).length.should.equal 2

            rest.del("#{url}/clients/bob").on 'complete', (data) =>
              data.clients.should.not.include 'bob'
              data.clients.should.include 'joe'
              Object.keys(data.clients).length.should.equal 1
              done()

  it "should be able to add attributes to a client"

  it "should be able to remove attributes from a client"

  it "should be able to retrieve a detailed list of clients"
