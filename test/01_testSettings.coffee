vows   = require 'vows'
assert = require 'assert'

settings = require '../settings.coffee'

exports.testSettings = vows.describe("Testing settings file").addBatch
  'Testing the contents of settings.coffee':
    topic: ()->
      return settings

    'we have session keys': (settings)->
      assert.isString settings.session.cookie
      assert.isString settings.session.secret
