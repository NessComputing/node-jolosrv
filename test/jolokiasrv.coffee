rest = require 'request'
express = require 'express'
http = require 'http'
util = require 'util'

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
    Object.keys(js.jclients).should.have.length 0
    js.add_client('test', url_href)
    Object.keys(js.jclients).should.include "test"
    js.jclients['test'].client.url.hostname.should.equal 'localhost'
    js.jclients['test'].client.url.port.should.equal '1234'
    js.jclients['test'].client.url.href.should.equal url_href
    Object.keys(js.jclients['test'].attributes).should.have.length 0
    done()

  it "should be able to return a list of clients", (done) ->
    url_href1 = 'http://localhost:1234/jolokia/'
    url_href2 = 'http://localhost:1235/jolokia/'
    Object.keys(js.jclients).should.have.length 0
    js.add_client('bob', url_href1)
    js.add_client('joe', url_href2)
    clients = js.list_clients()
    clients.should.have.length 2
    clients.should.include 'bob'
    clients.should.include 'joe'
    done()

  it "should be able to remove a client", (done) ->
    url_href1 = 'http://localhost:1234/jolokia/'
    url_href2 = 'http://localhost:1235/jolokia/'
    Object.keys(js.jclients).should.have.length 0
    js.add_client('bob', url_href1)
    js.add_client('joe', url_href2)
    clients = js.list_clients()
    clients.should.have.length 2
    js.remove_client('bob')
    clients = js.list_clients()
    clients.should.have.length 1
    clients.should.include 'joe'
    done()

  it "should be able to add attributes to a client", (done) ->
    url_href = 'http://localhost:1234/jolokia/'
    js.add_client 'test', url_href
    , 'java.lang:name=ConcurrentMarkSweep,type=GarbageCollector':
      'CollectionTime':
        graph:
          host: "examplehost.domain.com"
          units: "gc/sec"
          slope: "both"
          tmax: 60
          dmax: 180

    assert.equal(js.jclients.hasOwnProperty('test'), true)
    client = js.jclients['test']
    Object.keys(client).should.have.length 3
    assert.equal(client.hasOwnProperty('client'), true)
    assert.equal(client.hasOwnProperty('attributes'), true)
    assert.equal(client['attributes'].hasOwnProperty(
      'java.lang:name=ConcurrentMarkSweep,type=GarbageCollector'), true)
    assert.equal(
      client['attributes']\
      ['java.lang:name=ConcurrentMarkSweep,type=GarbageCollector']\
      .hasOwnProperty('CollectionTime'), true)
    done()

  it "should be able to add attributes that are hash lookups to a client"
  , (done) ->
    url_href = 'http://localhost:1234/jolokia/'
    js.add_client 'test', url_href
    , 'java.lang:name=ConcurrentMarkSweep,type=GarbageCollector':
      'LastGcInfo.memoryUsageAfterGc':
        graph:
          host: "examplehost.domain.com"
          units: "gc/sec"
          slope: "both"
          tmax: 60
          dmax: 180

    assert.equal(js.jclients.hasOwnProperty('test'), true)
    client = js.jclients['test']
    Object.keys(client).should.have.length 3
    assert.equal(client.hasOwnProperty('client'), true)
    assert.equal(client.hasOwnProperty('attributes'), true)
    assert.equal(client['attributes'].hasOwnProperty(
      'java.lang:name=ConcurrentMarkSweep,type=GarbageCollector'), true)
    assert.equal(
      client['attributes']\
      ['java.lang:name=ConcurrentMarkSweep,type=GarbageCollector']\
      .hasOwnProperty('LastGcInfo.memoryUsageAfterGc'), true)
    done()

  it "should be able to remove all attributes from a client", (done) ->
    url_href = 'http://localhost:1234/jolokia/'
    js.add_client 'test', url_href
    , 'java.lang:name=ConcurrentMarkSweep,type=GarbageCollector':
        'CollectionTime':
          graph:
            host: "examplehost.domain.com"
            units: "gc/sec"
            slope: "both"
            tmax: 60
            dmax: 180

    assert.equal(js.jclients.hasOwnProperty('test'), true)
    client = js.jclients['test']
    Object.keys(client).should.have.length 3
    assert.equal(client['attributes'].hasOwnProperty(
      'java.lang:name=ConcurrentMarkSweep,type=GarbageCollector'), true)
    assert.equal(
      client['attributes']\
      ['java.lang:name=ConcurrentMarkSweep,type=GarbageCollector']
      .hasOwnProperty('CollectionTime'), true)

    js.remove_attributes('test')
    client = js.jclients['test']
    Object.keys(client['attributes']).should.have.length 0
    done()

  it "should be able to retrieve detailed info for a client", (done) ->
    url_href = 'http://localhost:1234/jolokia/'
    js.add_client 'test', url_href
    , 'java.lang:somegroup':
      'someattr':
        graph: {}

    client = js.info_client('test')
    assert.equal(client.hasOwnProperty('java.lang:somegroup'), true)
    assert.equal(client['java.lang:somegroup']\
      .hasOwnProperty('someattr'), true)
    assert.equal(client['java.lang:somegroup']['someattr']\
      .hasOwnProperty('graph'), true)
    assert.equal(Object.keys(
      client['java.lang:somegroup']['someattr']['graph']).length, 0)
    done()

  it "should be able to retrieve detailed info for all clients", (done) =>
    url_href = 'http://localhost:1234/jolokia/'
    js.add_client 'test', url_href
    , 'java.lang:somegroup':
      'someattr':
        graph: {}

    js.add_client 'test2', url_href
    , 'java.lang:somegroup':
      'someattr':
        graph: {}

    clients = js.info_all_clients()
    for k in ['test', 'test2']
      assert.equal(clients[k].hasOwnProperty('java.lang:somegroup'), true)
      assert.equal(clients[k]['java.lang:somegroup']\
        .hasOwnProperty('someattr'), true)
      assert.equal(clients[k]['java.lang:somegroup']['someattr']\
        .hasOwnProperty('graph'), true)
      assert.equal(Object.keys(
        clients[k]['java.lang:somegroup']['someattr']['graph']).length, 0)
    done()

  it "should be able to generate an intelligent jolokia query", (done) =>
    url_href = 'http://localhost:1234/jolokia/'
    js.add_client 'test', url_href
    , [
        { mbean: 'java.lang:name=ConcurrentMarkSweep,type=GarbageCollector',
        attributes: [
          { name: 'CollectionCount'
          graph:
            name: "GC_Collection_Count"
            description: "GC Collection Count"
            units: "gc count"
            type: "int32" }
        ] },
        { mbean: 'java.lang:type=Memory',
        attributes: [
          { name: 'HeapMemoryUsage'
          composites: [
            { name: 'init',
            graph:
              name: "Heap_init"
              description: "Initial Heap Memory Usage"
              units: "bytes"
              type: "int32" }
          ] }
        ] }
      ]

    attributes = js.info_client('test')
    query_info = js.generate_query_info(attributes)
    query_info.should.have.length 2
    for q in query_info
      Object.keys(q).should.include('mbean')
      Object.keys(q).should.include('attribute')
      if q.composites.length > 0
        q.mbean.should.equal 'java.lang:type=Memory'
        q.attribute.should.equal 'HeapMemoryUsage'
        q.composites[0].name.should.equal 'init'
        q.composites[0].graph.name.should.equal 'Heap_init'
        q.composites[0].graph.type.should.equal 'int32'
      else
        q.mbean.should.equal \
          'java.lang:name=ConcurrentMarkSweep,type=GarbageCollector'
        q.attribute.should.equal 'CollectionCount'
        q.graph.name.should.equal 'GC_Collection_Count'
        q.graph.type.should.equal 'int32'
    done()

  it "should be able to convert attributes to a hash", (done) =>
    url_href = 'http://localhost:47432/jolokia/'
    js.add_client 'test', url_href
    , [
      { mbean: 'java.lang:name=ConcurrentMarkSweep,type=GarbageCollector',
      attributes: [
        { name: 'CollectionCount'
        graph:
          name: "GC_Collection_Count"
          description: "GC Collection Count"
          units: "gc count"
          type: "int32" },

        { name: 'LastGcInfo'
        composites: [
          { name: 'memoryUsageBeforeGC|Code Cache|init',
          graph:
            name: "MemoryUsage_Before_GC_Code_Cache_Init"
            description: "Code Cache (Init) Memory Usage Before GC"
            units: "bytes"
            type: "int32" }
        ] }
      ] },
    ]

    js.convert_attribs_to_hash js.info_client('test'), (err, result) =>
      r = result['java.lang:name=ConcurrentMarkSweep,type=GarbageCollector']
      Object.keys(r).should.have.length 2
      for item in Object.keys(r)
        if item == 'CollectionCount'
          Object.keys(r[item]).should.have.length 1
          Object.keys(r[item]).should.include 'graph'
          Object.keys(r[item].graph).should.have.length 4
        else if item == 'LastGcInfo'
          Object.keys(r[item]).should.have.length 1
          Object.keys(r[item]).should
          .include 'memoryUsageBeforeGC|Code Cache|init'
          Object.keys(r[item]['memoryUsageBeforeGC|Code Cache|init']).should
          .include 'graph'
          Object.keys(r[item]['memoryUsageBeforeGC|Code Cache|init'].graph)
          .should.have.length 4
        else
          throw new Error("Should never get here")
      done()

  it "should be able to query a basic jolokia mbean", (done) =>
    post_data = () =>
      url_href = 'http://localhost:47432/jolokia/'
      js.add_client 'test', url_href
      , [
        { mbean: 'java.lang:name=ConcurrentMarkSweep,type=GarbageCollector',
        attributes: [
          { name: 'CollectionCount'
          graph:
            name: "GC_Collection_Count"
            description: "GC Collection Count"
            units: "gc count"
            type: "int32" }
        ] }
      ]

      js.query_jolokia 'test', (err, resp) =>
        # console.log resp
        # resp.should.equal 46060
        srv.close()
        done()

    app = express()
    app.use express.bodyParser()
    app.post '/jolokia', (req, res, next) =>
      return_package = [
        { value: 46060
        request:
          type: 'read'
          mbean: 'java.lang:name=ConcurrentMarkSweep,type=GarbageCollector'
          attribute: 'CollectionCount'
        timestamp: 1356650995
        status: 200 }
      ]
      res.json 200, return_package

    srv = http.createServer(app)
    srv.listen(47432, post_data)

  # it "should be able to query a composite jolokia mbean", (done) =>
  #   post_data = () =>
  #     url_href = 'http://localhost:47432/jolokia/'
  #     js.add_client 'test', url_href
  #     , [
  #       { mbean: 'java.lang:type=Memory',
  #       attributes: [
  #         { name: 'HeapMemoryUsage'
  #         composites: [
  #           { name: 'init',
  #           graph:
  #             name: "Heap_init"
  #             description: "Initial Heap Memory Usage"
  #             units: "bytes"
  #             type: "int32" }
  #         ] }
  #       ] }
  #     ]
      
  #     js.query_jolokia 'test', (err, resp) =>
  #       console.log resp
  #       # resp.memoryUsageAfterGc['Code Cache'].init.should.equal 2555904
  #       srv.close()
  #       done()

  #   app = express()
  #   app.use express.bodyParser()
  #   app.post '/jolokia', (req, res, next) =>
  #     return_package = 
  #       status: 200
  #       timestamp: 1357339120
  #       request:
  #         attribute: 'HeapMemoryUsage'
  #         type: 'read'
  #         mbean: 'java.lang:type=Memory'
  #       value:
  #         used: 257367360
  #         init: 393561088
  #         max: 2602041344
  #         committed: 2602041344
  #     res.json 200, return_package

  #   srv = http.createServer(app)
  #   srv.listen(47432, post_data)

  # it "should be able to query a multilevel composite jolokia mbean", (done) =>
  #   post_data = () =>
  #     url_href = 'http://localhost:47432/jolokia/'
  #     js.add_client 'test', url_href
  #     , [
  #       { mbean: 'java.lang:name=ParNew,type=GarbageCollector',
  #       attributes: [
  #         { name: 'LastGcInfo'
  #         composites: [
  #           { name: 'memoryUsageBeforeGC|Code Cache|init',
  #           graph:
  #             name: "MemoryUsage_Before_GC_Code_Cache_Init"
  #             description: "Code Cache (Init) Memory Usage Before GC"
  #             units: "bytes"
  #             type: "int32" }
  #         ] }
  #       ] }
  #     ]

  #     js.query_jolokia 'test', (err, resp) =>
  #       resp.memoryUsageAfterGc['Code Cache'].init.should.equal 2555904
  #       srv.close()
  #       done()

  #   app = express()
  #   app.use express.bodyParser()
  #   app.post '/jolokia', (req, res, next) =>
  #     return_package = 
  #       status: 200
  #       timestamp: 1356657870
  #       duration: 10
  #       request:
  #         attribute: 'LastGcInfo'
  #         type: 'read'
  #         mbean: 'java.lang:name=ParNew,type=GarbageCollector'
  #       value:
  #         id: 118583
  #         memoryUsageBeforeGc: 
  #           'Code Cache': 
  #             init: 2555904
  #             committed: 9764864
  #             used: 9589824
  #             max: 50331648
  #           'CMS Perm Gen': 
  #             init: 21757952
  #             committed: 75091968
  #             used: 44995904
  #             max: 268435456
  #           'CMS Old Gen': 
  #             init: 262406144
  #             committed: 1973878784
  #             used: 1257080824
  #             max: 1973878784
  #           'Par Eden Space': 
  #             init: 104988672
  #             committed: 558432256
  #             used: 558432256
  #             max: 558432256
  #           'Par Survivor Space': 
  #             init: 13107200
  #             committed: 69730304
  #             used: 6333344
  #             max: 69730304
  #         GcThreadCount: 11,
  #         endTime: 521639692
  #         startTime: 521639682
  #         memoryUsageAfterGc: 
  #           'Code Cache': 
  #             init: 2555904
  #             committed: 9764864
  #             used: 9589824
  #             max: 50331648
  #           'CMS Perm Gen': 
  #             init: 21757952
  #             committed: 75091968
  #             used: 44995904
  #             max: 268435456
  #           'CMS Old Gen': 
  #             init: 262406144
  #             committed: 1973878784
  #             used: 1257559928
  #             max: 1973878784
  #           'Par Eden Space':
  #             init: 104988672
  #             committed: 558432256
  #             used: 0
  #             max: 558432256
  #           'Par Survivor Space': 
  #             init: 13107200
  #             committed: 69730304
  #             used: 8012272
  #             max: 69730304
  #     res.json 200, return_package

  #   srv = http.createServer(app)
  #   srv.listen(47432, post_data)

  # it "should support templating for metric aggregation"

  # it "should support compound templates"

  # it "should have sane default graph configurations"
