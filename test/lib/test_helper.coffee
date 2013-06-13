global.path = require 'path'
global.os = require 'os'

global.chai = require 'chai'
global.assert = chai.assert

chai.should()

config = require 'nconf'
CLI = require '../../src/cli'

global.cli = new CLI()
global.config = config

config.overrides
  template_dir: path.resolve(__dirname, '..', 'templates')
  gmetric: '127.0.0.1'
  gPort: 43278
