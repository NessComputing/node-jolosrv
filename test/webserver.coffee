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
    rest.postJson("#{url}/clients",
      name: "bob"
      url: "http://localhost:1234/jolokia/"
    ).on 'complete', (data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234/jolokia/'
      Object.keys(data.attributes).length.should.equal 0
      done()

  it "throws 400 when adding a client without a name", (done) ->
    rest.postJson("#{url}/clients",
      url: "http://localhost:1234/jolokia/"
    ).on 'complete', (data, res) =>
      res.statusCode.should.equal 400
      done()

  it "throws 400 when adding a client without a url", (done) ->
    rest.postJson("#{url}/clients",
      name: "bob"
    ).on 'complete', (data, res) =>
      res.statusCode.should.equal 400
      done()

  it "should be able to update a client", (done) ->
    rest.postJson("#{url}/clients",
      name: "bob"
      url: "http://localhost:1234/jolokia/"
    ).on 'complete', (data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234/jolokia/'
      Object.keys(data.attributes).length.should.equal 0

      rest.postJson("#{url}/clients",
        name: "bob"
        url: "http://localhost:1235/jolokia/"
      ).on 'complete', (data) =>
        data.name.should.equal 'bob'
        data.url.should.equal 'http://localhost:1235/jolokia/'
        Object.keys(data.attributes).length.should.equal 0
        done()

  it "should be able to return a list of clients", (done) ->
    rest.postJson("#{url}/clients",
      name: "bob"
      url: "http://localhost:1234/jolokia/"
    ).on 'complete', (data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234/jolokia/'
      Object.keys(data.attributes).length.should.equal 0
      rest.get("#{url}/clients").on 'complete', (data) =>
        data.clients.should.include 'bob'
        Object.keys(data.clients).length.should.equal 1
        done()

  it "should be able to remove a client", (done) ->
    rest.postJson("#{url}/clients",
      name: "bob"
      url: "http://localhost:1234/jolokia/"
    ).on 'complete', (data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234/jolokia/'
      
      rest.get("#{url}/clients").on 'complete', (data) =>
        data.clients.should.include 'bob'
        Object.keys(data.clients).length.should.equal 1

        rest.postJson("#{url}/clients",
          name: "joe"
          url: "http://localhost:1235/jolokia/"
        ).on 'complete', (data) =>
          data.name.should.equal 'joe'
          data.url.should.equal 'http://localhost:1235/jolokia/'

          rest.get("#{url}/clients").on 'complete', (data) =>
            data.clients.should.include 'bob'
            data.clients.should.include 'joe'
            Object.keys(data.clients).length.should.equal 2

            rest.del("#{url}/clients/bob").on 'complete', (data) =>
              data.clients.should.not.include 'bob'
              data.clients.should.include 'joe'
              Object.keys(data.clients).length.should.equal 1
              done()

  it "should be able to add attributes to a client" #, (done) ->
    # url_href = "http://localhost:1234/jolokia/"
    # attrs = 
    #   "java.lang":
    #     "name=ConcurrentMarkSweep,type=GarbageCollector":
    #       graph:
    #         host: "examplehost.domain.com"
    #         units: "gc/sec"
    #         slope: "both"
    #         tmax: 60
    #         dmax: 180

    # rest.postJson("#{url}/clients",
    #   name: "bob"
    #   url: url_href
    #   attributes: attrs

    # ).on 'complete', (data) =>
    #   data.name.should.equal 'bob'
    #   data.url.should.equal 'http://localhost:1234/jolokia/'
    #   console.log data.attributes
    #   done()

  it "should be able to remove attributes from a client"
    # rest.postJson("#{url}/clients",
    #   name: "bob"
    #   url: url_href
    # ).on 'complete', (data) =>

  it "should be able to retrieve a detailed list of clients"
