rest = require 'request'

logger = require '../src/logger'
WebServer = require '../src/webserver'

describe 'WebServer', ->
  ws = null

  url = "http://127.0.0.1:#{config.get('port')}"

  beforeEach (done) ->
    logger.clear()
    ws = new WebServer(config.get('port'))
    done()

  afterEach (done) ->
    ws.srv.close()
    done()

  it "should show the version info", (done) ->
    rest.get "#{url}/", json: true, (err, res, data) ->
      data.name.should.equal "jolosrv"
      assert.notEqual data.version, undefined
      done()

  it "should be able to list templates", (done) ->
    ws.jsrv.load_all_templates () =>
      rest.get "#{url}/templates", (err, res, data) ->
        JSON.parse(data).templates.length.should.be.above(0)
        done()

  it "should be able to add a client", (done) ->
    rest.post "#{url}/clients", json: true,
    body:
      name: "bob"
      url: "http://localhost:1234/jolokia/"
    , (err, res, data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234/jolokia/'
      assert.equal(data.template, undefined)
      done()

  it "throws 400 when adding a client without a name", (done) ->
    rest.post "#{url}/clients", json: true,
    body:
      url: "http://localhost:1234/jolokia/"
    , (err, res, data) =>
      res.statusCode.should.equal 400
      done()

  it "throws 400 when adding a client without a url", (done) ->
    rest.post "#{url}/clients", json: true,
    body:
      name: "bob"
    , (err, res, data) =>
      res.statusCode.should.equal 400
      done()

  it "should be able to update a client", (done) ->
    rest.post "#{url}/clients", json: true,
    body:
      name: "bob"
      url: "http://localhost:1234/jolokia/"
    , (err, res, data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234/jolokia/'
      assert.equal(data.template, undefined)

      rest.post "#{url}/clients", json: true,
      body:
        name: "bob"
        url: "http://localhost:1235/jolokia/"
      , (err, res, data) =>
        data.name.should.equal 'bob'
        data.url.should.equal 'http://localhost:1235/jolokia/'
        assert.equal(data.template, undefined)
        done()

  it "should be able to return a list of clients", (done) ->
    rest.post "#{url}/clients", json: true,
    body:
      name: "bob"
      url: "http://localhost:1234/jolokia/"
    , (err, res, data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234/jolokia/'
      assert.equal(data.template, undefined)
      rest.get "#{url}/clients", json: true, (err, res, data) =>
        data.clients.should.include 'bob'
        Object.keys(data.clients).length.should.equal 1
        done()

  it "should be able to remove a client", (done) ->
    rest.post "#{url}/clients", json: true,
    body:
      name: "bob"
      url: "http://localhost:1234/jolokia/"
    , (err, res, data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234/jolokia/'
      
      rest.get "#{url}/clients", json: true, (err, res, data) =>
        data.clients.should.include 'bob'
        Object.keys(data.clients).length.should.equal 1

        rest.post "#{url}/clients", json: true,
        body:
          name: "joe"
          url: "http://localhost:1235/jolokia/"
        , (err, res, data) =>
          data.name.should.equal 'joe'
          data.url.should.equal 'http://localhost:1235/jolokia/'

          rest.get "#{url}/clients", json: true, (err, res, data) =>
            data.clients.should.include 'bob'
            data.clients.should.include 'joe'
            Object.keys(data.clients).length.should.equal 2

            rest.del "#{url}/clients/bob", json: true, (err, res, data) =>
              rest.get "#{url}/clients", json: true, (err, res, data) =>
                data.clients.should.not.include 'bob'
                data.clients.should.include 'joe'
                Object.keys(data.clients).length.should.equal 1
                done()

  it "should be able to modify the template of a client", (done) ->
    url_href = "http://localhost:1234/jolokia/"
    template = "example_template"

    rest.post "#{url}/clients", json: true,
    body:
      name: "bob"
      url: url_href
      template: template
    , (err, res, data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234/jolokia/'
      data.template.should.equal "example_template"
      done()

  it "should be able to retrieve detailed info for a client", (done) ->
    url_href = "http://localhost:1234/jolokia/"
    template = "example_template"

    rest.post "#{url}/clients", json: true,
    body:
      name: "bob"
      url: url_href
      template: template
    , (err, res, data) =>
      rest.get "#{url}/clients/bob", (err, res, data) =>
        done()

  it "should be able to retrieve a detailed list of clients", (done) ->
    url_href = "http://localhost:1234/jolokia/"
    template = 'concurrentms_collector'

    rest.post "#{url}/clients", json: true,
    body:
      name: "bob"
      url: url_href
      template: template
    , (err, res, data) =>
      rest.post "#{url}/clients", json: true,
      body:
        name: "joe"
        url: url_href
        template: template
      , (err, res, data) =>      
        rest.get "#{url}/clients", json: true,
        qs:
          info: true
        , (err, res, data) =>
          client_list = Object.keys(data.clients)
          client_list.length.should.equal 2
          client_list.should.include 'bob'
          client_list.should.include 'joe'

          for k in ['bob', 'joe']
            data.clients[k].mappings.length.should.equal 1
            ainfo = data.clients[k].mappings[0]
            ainfo.mbean.should.equal \
            'java.lang:name=ConcurrentMarkSweep,type=GarbageCollector'
            ainfo.attributes.length.should.equal 1
            ainfo.attributes[0].name.should.equal 'CollectionTime'

            ginfo = ainfo.attributes[0].graph
            ginfo.name.should.equal 'Collection_Time'
            ginfo.units.should.equal 'gc/sec'
            ginfo.slope.should.equal 'both'
            ginfo.tmax.should.equal 60
            ginfo.dmax.should.equal 180
          done()
