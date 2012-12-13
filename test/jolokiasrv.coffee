rest = require 'restler'
dgram = require 'dgram'

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
    js.add_attribute 'test'
    , 'java.lang'
    , 'name=ConcurrentMarkSweep,type=GarbageCollector'
    , 'CollectionTime'
    , graph:
      host: "examplehost.domain.com"
      units: "gc/sec"
      slope: "both"
      tmax: 60
      dmax: 180

    clients = js.jclients
    Object.keys(clients).length.should.equal 1
    assert.equal(clients.hasOwnProperty('test'), true)
    assert.equal(clients.test.hasOwnProperty('java.lang'), true)
    assert.equal(
      clients.test['java.lang'].hasOwnProperty(
        'name=ConcurrentMarkSweep,type=GarbageCollector'), true)
    assert.equal(
      clients.test['java.lang']\
      ['name=ConcurrentMarkSweep,type=GarbageCollector'].hasOwnProperty(
        'CollectionTime'), true)

    done()

  it "should be able to add attributes that are hash lookups to a client"
  , (done) ->
    js.add_attribute 'test'
    , 'java.lang'
    , 'name=ConcurrentMarkSweep,type=GarbageCollector'
    , 'LastGcInfo.memoryUsageAfterGc'
    , graph:
      host: "examplehost.domain.com"
      units: "gc/sec"
      slope: "both"
      tmax: 60
      dmax: 180

    clients = js.jclients
    Object.keys(clients).length.should.equal 1
    assert.equal(clients.hasOwnProperty('test'), true)
    assert.equal(clients.test.hasOwnProperty('java.lang'), true)
    assert.equal(
      clients.test['java.lang'].hasOwnProperty(
        'name=ConcurrentMarkSweep,type=GarbageCollector'), true)
    assert.equal(
      clients.test['java.lang']\
      ['name=ConcurrentMarkSweep,type=GarbageCollector'].hasOwnProperty(
        'LastGcInfo.memoryUsageAfterGc'), true)

    done()

  it "should be able to remove all attributes from a client", (done) ->
    js.add_attribute 'test'
    , 'java.lang'
    , 'name=ConcurrentMarkSweep,type=GarbageCollector'
    , 'CollectionTime'
    , graph:
      host: "examplehost.domain.com"
      units: "gc/sec"
      slope: "both"
      tmax: 60
      dmax: 180

    clients = js.jclients
    Object.keys(clients).length.should.equal 1
    assert.equal(clients.hasOwnProperty('test'), true)
    assert.equal(clients.test.hasOwnProperty('java.lang'), true)
    assert.equal(
      clients.test['java.lang'].hasOwnProperty(
        'name=ConcurrentMarkSweep,type=GarbageCollector'), true)
    assert.equal(
      clients.test['java.lang']\
      ['name=ConcurrentMarkSweep,type=GarbageCollector'].hasOwnProperty(
        'CollectionTime'), true)

    js.remove_attributes('test', 'java.lang')
    console.log js.jclients
    done()

  it "should be able to retrieve jolokia stats for the given attributes"

  it "should be able to update a gmond endpoint on an interval"
    # socksrv = dgram.createSocket("udp4")
    # receive_count = 0
    # socksrv.on 'message', (msg, rinfo) =>
    #   receive_count += 1
    #   console.log "server got: #{msg} from #{rinfo.address}:#{rinfo.port}"
    #   if receive_count >= 3
    #     socksrv.close()
    #     done()
    #
    # socksrv.bind(43278)
    #
