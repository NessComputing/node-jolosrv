rest = require 'restler'

JolokiaSrv = require '../src/jolokiasrv'

describe 'JolokiaSrv', ->
  js = null

  beforeEach (done) ->
    js = new JolokiaSrv(0)
    done()

  afterEach (done) ->
    js = null
    done()

  it "should be able to add a client", (done) ->
    url_href = 'http://localhost:1234/jolokia/'
    Object.keys(js.jclients).length.should.equal 0
    js.add_client('test', url_href)
    Object.keys(js.jclients).should.include "test"
    js.jclients['test'].client.url.hostname.should.equal 'localhost'
    js.jclients['test'].client.url.port.should.equal '1234'
    js.jclients['test'].client.url.href.should.equal url_href
    Object.keys(js.jclients['test'].attributes).length.should.equal 0
    done()

  it "should be able to return a list of clients", (done) ->
    url_href1 = 'http://localhost:1234/jolokia/'
    url_href2 = 'http://localhost:1235/jolokia/'
    Object.keys(js.jclients).length.should.equal 0
    js.add_client('bob', url_href1)
    js.add_client('joe', url_href2)
    clients = js.list_clients()
    clients.length.should.equal 2
    clients.should.include 'bob'
    clients.should.include 'joe'
    done()

  it "should be able to remove a client", (done) ->
    url_href1 = 'http://localhost:1234/jolokia/'
    url_href2 = 'http://localhost:1235/jolokia/'
    Object.keys(js.jclients).length.should.equal 0
    js.add_client('bob', url_href1)
    js.add_client('joe', url_href2)
    clients = js.list_clients()
    clients.length.should.equal 2
    js.remove_client('bob')
    clients = js.list_clients()
    clients.length.should.equal 1
    clients.should.include 'joe'
    done()

  it "should be able to add attributes to a client", (done) ->
    url_href = 'http://localhost:1234/jolokia/'
    js.add_client 'test', url_href
    , 'java.lang':
      'name=ConcurrentMarkSweep,type=GarbageCollector':
        'CollectionTime':
          graph:
            host: "examplehost.domain.com"
            units: "gc/sec"
            slope: "both"
            tmax: 60
            dmax: 180

    assert.equal(js.jclients.hasOwnProperty('test'), true)
    client = js.jclients['test']
    Object.keys(client).length.should.equal 2
    assert.equal(client.hasOwnProperty('client'), true)
    assert.equal(client.hasOwnProperty('attributes'), true)
    assert.equal(client['attributes'].hasOwnProperty('java.lang'), true)
    assert.equal(
      client['attributes']['java.lang'].hasOwnProperty(
        'name=ConcurrentMarkSweep,type=GarbageCollector'), true)
    assert.equal(
      client['attributes']['java.lang']\
      ['name=ConcurrentMarkSweep,type=GarbageCollector'].hasOwnProperty(
        'CollectionTime'), true)
    done()

  it "should be able to add attributes that are hash lookups to a client"
  , (done) ->
    url_href = 'http://localhost:1234/jolokia/'
    js.add_client 'test', url_href
    , 'java.lang':
      'name=ConcurrentMarkSweep,type=GarbageCollector':
        'LastGcInfo.memoryUsageAfterGc':
          graph:
            host: "examplehost.domain.com"
            units: "gc/sec"
            slope: "both"
            tmax: 60
            dmax: 180

    assert.equal(js.jclients.hasOwnProperty('test'), true)
    client = js.jclients['test']
    Object.keys(client).length.should.equal 2
    assert.equal(client.hasOwnProperty('client'), true)
    assert.equal(client.hasOwnProperty('attributes'), true)
    assert.equal(client['attributes'].hasOwnProperty('java.lang'), true)
    assert.equal(
      client['attributes']['java.lang'].hasOwnProperty(
        'name=ConcurrentMarkSweep,type=GarbageCollector'), true)
    assert.equal(
      client['attributes']['java.lang']\
      ['name=ConcurrentMarkSweep,type=GarbageCollector'].hasOwnProperty(
        'LastGcInfo.memoryUsageAfterGc'), true)
    done()

  it "should be able to remove all attributes from a client", (done) ->
    url_href = 'http://localhost:1234/jolokia/'
    js.add_client 'test', url_href
    , 'java.lang':
      'name=ConcurrentMarkSweep,type=GarbageCollector':
        'CollectionTime':
          graph:
            host: "examplehost.domain.com"
            units: "gc/sec"
            slope: "both"
            tmax: 60
            dmax: 180

    assert.equal(js.jclients.hasOwnProperty('test'), true)
    client = js.jclients['test']
    Object.keys(client).length.should.equal 2
    assert.equal(client['attributes'].hasOwnProperty('java.lang'), true)
    assert.equal(
      client['attributes']['java.lang'].hasOwnProperty(
        'name=ConcurrentMarkSweep,type=GarbageCollector'), true)
    assert.equal(
      client['attributes']['java.lang']\
      ['name=ConcurrentMarkSweep,type=GarbageCollector'].hasOwnProperty(
        'CollectionTime'), true)

    js.remove_attributes('test')
    client = js.jclients['test']
    Object.keys(client['attributes']).length.should.equal 0
    done()

  it "should be able to retrieve detailed info for a client", (done) ->
    url_href = 'http://localhost:1234/jolokia/'
    js.add_client 'test', url_href
    , 'java.lang':
      'somegroup':
        'someattr':
          data: {}

    client = js.info_client('test')
    assert.equal(client.hasOwnProperty('java.lang'), true)
    assert.equal(client['java.lang'].hasOwnProperty('somegroup'), true)
    assert.equal(client['java.lang']['somegroup']\
      .hasOwnProperty('someattr'), true)
    assert.equal(client['java.lang']['somegroup']['someattr']\
      .hasOwnProperty('data'), true)
    assert.equal(Object.keys(
      client['java.lang']['somegroup']['someattr']['data']).length, 0)
    done()

  it "should be able to retrieve detailed info for all clients", (done) =>
    url_href = 'http://localhost:1234/jolokia/'
    js.add_client 'test', url_href
    , 'java.lang':
      'somegroup':
        'someattr':
          data: {}

    js.add_client 'test2', url_href
    , 'java.lang':
      'somegroup':
        'someattr':
          data: {}

    clients = js.info_all_clients()
    for k in ['test', 'test2']
      assert.equal(clients[k].hasOwnProperty('java.lang'), true)
      assert.equal(clients[k]['java.lang'].hasOwnProperty('somegroup'), true)
      assert.equal(clients[k]['java.lang']['somegroup']\
        .hasOwnProperty('someattr'), true)
      assert.equal(clients[k]['java.lang']['somegroup']['someattr']\
        .hasOwnProperty('data'), true)
      assert.equal(Object.keys(
        clients[k]['java.lang']['somegroup']['someattr']['data']).length, 0)
    done()
