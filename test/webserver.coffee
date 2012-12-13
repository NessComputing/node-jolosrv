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

  it "should be able to add attributes to a client", (done) ->
    url_href = "http://localhost:1234/jolokia/"
    attrs = 
      "java.lang":
        "name=ConcurrentMarkSweep,type=GarbageCollector":
          CollectionTime:
            graph:
              host: "examplehost.domain.com"
              units: "gc/sec"
              slope: "both"
              tmax: 60
              dmax: 180

    rest.postJson("#{url}/clients",
      name: "bob"
      url: url_href
      attributes: attrs
    ).on 'complete', (data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234/jolokia/'
      assert.equal(data.attributes.hasOwnProperty('java.lang'), true)
      assert.equal(data.attributes['java.lang'].hasOwnProperty(
        'name=ConcurrentMarkSweep,type=GarbageCollector'), true)
      assert.equal(data.attributes['java.lang']\
        ['name=ConcurrentMarkSweep,type=GarbageCollector']\
        .hasOwnProperty('CollectionTime'), true)
      assert.equal(data.attributes['java.lang']\
        ['name=ConcurrentMarkSweep,type=GarbageCollector']\
        ['CollectionTime'].hasOwnProperty('graph'), true)

      graph_attrs = data.attributes['java.lang']\
        ['name=ConcurrentMarkSweep,type=GarbageCollector']\
        ['CollectionTime']['graph']
      graph_attrs.host.should.equal "examplehost.domain.com"
      graph_attrs.units.should.equal "gc/sec"
      graph_attrs.slope.should.equal "both"
      graph_attrs.tmax.should.equal 60
      graph_attrs.dmax.should.equal 180
      done()

  it "should be able to add attributes that are hash lookups to a client",
  (done) ->
    url_href = "http://localhost:1234/jolokia/"
    attrs = 
      "java.lang":
        "name=ConcurrentMarkSweep,type=GarbageCollector":
          'LastGcInfo.memoryUsageAfterGc':
            graph:
              host: "examplehost.domain.com"
              units: "gc/sec"
              slope: "both"
              tmax: 60
              dmax: 180

    rest.postJson("#{url}/clients",
      name: "bob"
      url: url_href
      attributes: attrs
    ).on 'complete', (data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234/jolokia/'
      assert.equal(data.attributes.hasOwnProperty('java.lang'), true)
      assert.equal(data.attributes['java.lang'].hasOwnProperty(
        'name=ConcurrentMarkSweep,type=GarbageCollector'), true)
      assert.equal(data.attributes['java.lang']\
        ['name=ConcurrentMarkSweep,type=GarbageCollector']\
        .hasOwnProperty('LastGcInfo.memoryUsageAfterGc'), true)
      assert.equal(data.attributes['java.lang']\
        ['name=ConcurrentMarkSweep,type=GarbageCollector']\
        ['LastGcInfo.memoryUsageAfterGc'].hasOwnProperty('graph'), true)

      graph_attrs = data.attributes['java.lang']\
        ['name=ConcurrentMarkSweep,type=GarbageCollector']\
        ['LastGcInfo.memoryUsageAfterGc']['graph']
      graph_attrs.host.should.equal "examplehost.domain.com"
      graph_attrs.units.should.equal "gc/sec"
      graph_attrs.slope.should.equal "both"
      graph_attrs.tmax.should.equal 60
      graph_attrs.dmax.should.equal 180
      done()

  it "should be able to retrieve detailed info for a client", (done) ->
    url_href = "http://localhost:1234/jolokia/"
    attrs = 
      "java.lang":
        "name=ConcurrentMarkSweep,type=GarbageCollector":
          CollectionTime:
            graph:
              host: "examplehost.domain.com"
              units: "gc/sec"
              slope: "both"
              tmax: 60
              dmax: 180

    rest.postJson("#{url}/clients",
      name: "bob"
      url: url_href
      attributes: attrs
    ).on 'complete', (data) =>
      rest.get("#{url}/clients/bob").on 'complete', (data) =>
        data = data.info
        assert.equal(data.hasOwnProperty('java.lang'), true)
        assert.equal(data['java.lang'].hasOwnProperty(
          'name=ConcurrentMarkSweep,type=GarbageCollector'), true)
        assert.equal(data['java.lang']\
          ['name=ConcurrentMarkSweep,type=GarbageCollector']\
          .hasOwnProperty('CollectionTime'), true)
        assert.equal(data['java.lang']\
          ['name=ConcurrentMarkSweep,type=GarbageCollector']\
          ['CollectionTime'].hasOwnProperty('graph'), true)

        graph_attrs = data['java.lang']\
        ['name=ConcurrentMarkSweep,type=GarbageCollector']\
        ['CollectionTime']['graph']
        graph_attrs.host.should.equal "examplehost.domain.com"
        graph_attrs.units.should.equal "gc/sec"
        graph_attrs.slope.should.equal "both"
        graph_attrs.tmax.should.equal 60
        graph_attrs.dmax.should.equal 180
        done()

  it "should be able to retrieve a detailed list of clients", (done) ->
    url_href = "http://localhost:1234/jolokia/"
    attrs = 
      "java.lang":
        "name=ConcurrentMarkSweep,type=GarbageCollector":
          CollectionTime:
            graph:
              host: "examplehost.domain.com"
              units: "gc/sec"
              slope: "both"
              tmax: 60
              dmax: 180

    rest.postJson("#{url}/clients",
      name: "bob"
      url: url_href
      attributes: attrs
    ).on 'complete', (data) =>
      rest.postJson("#{url}/clients",
        name: "joe"
        url: url_href
        attributes: attrs
      ).on 'complete', (data) =>      
        rest.get("#{url}/clients"
        , query: { info: true }).on 'complete', (data) =>
          clients = data.clients
          for k in ['bob', 'joe']
            assert.equal(clients[k].hasOwnProperty('java.lang'), true)
            assert.equal(clients[k]['java.lang'].hasOwnProperty(
              'name=ConcurrentMarkSweep,type=GarbageCollector'), true)
            assert.equal(clients[k]['java.lang']\
              ['name=ConcurrentMarkSweep,type=GarbageCollector']\
              .hasOwnProperty('CollectionTime'), true)
            assert.equal(clients[k]['java.lang']\
              ['name=ConcurrentMarkSweep,type=GarbageCollector']\
              ['CollectionTime'].hasOwnProperty('graph'), true)

            graph_attrs = clients[k]['java.lang']\
              ['name=ConcurrentMarkSweep,type=GarbageCollector']\
              ['CollectionTime']['graph']
            graph_attrs.host.should.equal "examplehost.domain.com"
            graph_attrs.units.should.equal "gc/sec"
            graph_attrs.slope.should.equal "both"
            graph_attrs.tmax.should.equal 60
            graph_attrs.dmax.should.equal 180
          done()

  it "should be able to remove attributes from a client", (done) ->
    url_href = "http://localhost:1234/jolokia/"
    attrs = 
      "java.lang":
        "name=ConcurrentMarkSweep,type=GarbageCollector":
          CollectionTime:
            graph:
              host: "examplehost.domain.com"
              units: "gc/sec"
              slope: "both"
              tmax: 60
              dmax: 180

    rest.postJson("#{url}/clients",
      name: "bob"
      url: url_href
      attributes: attrs
    ).on 'complete', (data) =>
      data.name.should.equal 'bob'
      data.url.should.equal 'http://localhost:1234/jolokia/'
      assert.equal(data.attributes.hasOwnProperty('java.lang'), true)
      assert.equal(data.attributes['java.lang'].hasOwnProperty(
        'name=ConcurrentMarkSweep,type=GarbageCollector'), true)
      assert.equal(data.attributes['java.lang']\
        ['name=ConcurrentMarkSweep,type=GarbageCollector']\
        .hasOwnProperty('CollectionTime'), true)
      assert.equal(data.attributes['java.lang']\
        ['name=ConcurrentMarkSweep,type=GarbageCollector']\
        ['CollectionTime'].hasOwnProperty('graph'), true)

      graph_attrs = data.attributes['java.lang']\
        ['name=ConcurrentMarkSweep,type=GarbageCollector']\
        ['CollectionTime']['graph']
      graph_attrs.host.should.equal "examplehost.domain.com"
      graph_attrs.units.should.equal "gc/sec"
      graph_attrs.slope.should.equal "both"
      graph_attrs.tmax.should.equal 60
      graph_attrs.dmax.should.equal 180
      rest.del("#{url}/clients/bob/attributes").on 'complete', (data) =>
        rest.get("#{url}/clients"
        , query: { info: true }).on 'complete', (data) =>
          clients = data.clients
          assert.equal(Object.keys(clients.bob).length, 0)
          done()

