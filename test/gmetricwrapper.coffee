GmetricWrapper = require '../src/gmetric_wrapper'

describe 'GmetricWrapper', ->
  gm = null

  beforeEach (done) ->
    gm = new GmetricWrapper()
    done()

  afterEach (done) ->
    gm = null
    done()

  it "should be able to get lookups for slope types", (done) ->
    gm.slope(0).should.equal 0
    gm.slope('zero').should.equal 0
    gm.slope('positive').should.equal 1
    gm.slope('negative').should.equal 2
    gm.slope('-1').should.equal 2
    gm.slope('both').should.equal 3
    gm.slope('wtfbbq').should.equal 4
    done()

  it "should be able to get lookups for value types", (done) ->
    gm.value_type("wtfbbq").should.equal 0
    gm.value_type("string").should.equal 1
    gm.value_type("ushrt").should.equal 2
    gm.value_type("unsigned_short").should.equal 2
    gm.value_type("short").should.equal 3
    gm.value_type("uint").should.equal 4
    gm.value_type("int").should.equal 5
    
    # BORKEN! Refs: https://github.com/jbuchbinder/node-gmetric/pull/2
    gm.value_type("float").should.equal 6
    gm.value_type("double").should.equal 7
    done()
