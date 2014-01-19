# In this file we will cover the ViewPort class while we test
# the webserver itself.  The viewport depends on Express
# which is embedded in the web server object

vows   = require 'vows'
assert = require 'assert'
request  = require 'request'

settings = require '../settings.coffee'
Web      = require '../lib/Web.coffee'
web = {}

port = process.env.PORT || "3000"
url = "http://localhost:#{port}"

listener = {}

# Valid container for testing getContainerDetails.
# this will be filled during the getUpContainers test.
# Therefore at least one running container is requred for tests to pass.
# Since this webApp can be run in a container, and will be advertised as such
# this wont be much of a concern.
containerId = ""

exports.testWebServer = vows.describe("Web Class").addBatch
  'Create an instance of Web class':
    topic: ()->
      web = new Web(settings)
      web.settings.scriptPath = __dirname + "/../"
      web.muteOutput = true

      return web

    'we get a web instance object back': (web)->
      assert.isObject web

    'it has inherited events': (web)->
      assert.isTrue web.hasEvents

    'it has inherited controller': (web)->
      assert.isTrue web.hasController

    'it has inherited docker': (web)->
      assert.isTrue web.hasDocker

    'it has a controller object': (web)->
      assert.isObject web.controller

    'it has inherited security': (web)->
      assert.isTrue web.hasSecurity

    'it has a defined log function': (web)->
      assert.isFunction web.log

    'it has not been configured, yet': (web)->
      assert.isUndefined web.configured

    ', configure the web server and add mocked routes':
      topic: ()->
        web.configure()

        # Mock '/mock' route and return a JSON obj to test for
        # LENGTH - 2
        web.app.get '/mock', (req, res)->
          res.send { success: true }

        # Mock '/api/random/:random'
        # LENGTH - 1
        web.app.get '/api/random/:random', (req, res)->
          res.send { success: true, random: req.params.random }

        return web

      'we get a configured web server': (web)->
        assert.isTrue web.configured

      'it has a redis session store': (web)->
        assert.isObject web.sessionStore

      'it hasViewPort, and a viewPort object with core methods': (web)->
        assert.equal web.hasViewPort, true
        assert.isObject web.viewPort

        methods = web.viewPort.methods
        hasGetViewByName          = false
        hasGetCarouselForViewName = false
        hasGetGlobalNavigation    = false
        hasGetUpContainers        = false
        hasGetAllContainers       = false
        hasGetAllImages           = false
        hasGetContainerDetails    = false
        hasGetContainerLogs       = false

        for id of methods
          switch methods[id]
            when "getViewByName"
              hasGetViewByName = true
            when "getCarouselForViewName"
              hasGetCarouselForViewName = true
            when "getGlobalNavigation"
              hasGetGlobalNavigation = true
            when "getUpContainers"
              hasGetUpContainers = true
            when "getAllContainers"
              hasGetAllContainers = true
            when "getAllImages"
              hasGetAllImages = true
            when "getContainerDetails"
              hasGetContainerDetails = true
            when "getContainerLogs"
              hasGetContainerLogs = true

        assert.equal hasGetViewByName, true
        assert.equal hasGetCarouselForViewName, true
        assert.equal hasGetGlobalNavigation, true
        assert.equal hasGetUpContainers, true
        assert.equal hasGetAllContainers, true
        assert.equal hasGetAllImages, true
        assert.equal hasGetContainerDetails, true
        assert.equal hasGetContainerLogs, true

        length = web.viewPort.methods.length > 1
        assert.equal length, true

      'it has an app fn reference': (web)->
        assert.isFunction web.app

      'it has our mocked /mock route, pushed to app': (web)->
        get = web.app.routes.get
        assert.equal get[get.length - 2].path, '/mock'

      'it has our mocked /api/random/:random, pushed to app': (web)->
        get = web.app.routes.get
        assert.equal get[get.length - 1].path, '/api/random/:random'

      'its not listening, yet': (web)->
        assert.isUndefined web.listening

      ', listen on port ':
        topic: ()->
          listener = web.createServer()
          return listener

        'server is listening': (web)->
          assert.isTrue web.listening
          assert.isObject web.listener

exports.testBadEndpoints = vows.describe("Test invalid Endpoints").addBatch
  'GET /invalid':
    topic: ()->
      request "#{url}/invalid", this.callback
      undefined

    'should have no err': (err, res, body)->
      assert.isNull err

    'should respond with a 404 not found': (err, res, body)->
      assert.equal res.statusCode, 404

    'should have a body': (err, res, body)->
      assert.isString body

exports.testWebServerRootEndpoint = vows.describe("Test / Endpoint").addBatch
  'GET /':
    topic: ()->
      request "#{url}/", this.callback
      undefined

    'should respond with a 200 OK': (e, res, body)->
      assert.equal res.statusCode, 200

    'should be a full HTML index page': (e, res, body)->
      hasHtmlTagBegin = false
      hasHtmlTagEnd   = false

      if body.indexOf("<html><head><title>") >= 0
        hasHtmlTagBegin = true

      if body.indexOf("</html>") >= 0
        hasHtmlTagEnd = true

      assert.equal hasHtmlTagBegin, true
      assert.equal hasHtmlTagEnd,   true

exports.testWebServerViewPortEndpoints = vows.describe("Test ViewPort Endpoints").addBatch
  'GET /api/view/geCarouselForViewName?name=index':
    topic: ()->
      request url + '/api/view/getCarouselForViewName?name=index', this.callback
      undefined

    'should respond with a 200 OK': (e, res, body)->
      assert.equal res.statusCode, 200

    'should have data returned': (e, res, body)->
      assert.equal JSON.parse(res.body).success, true
      assert.isString JSON.parse(res.body).html

  'GET /api/view/getGlobalNavigation?name=index':
    topic: ()->
      request url + '/api/view/getGlobalNavigation?name=index', this.callback
      undefined

    'should respond with a 200 OK': (e, res, body)->
      assert.equal res.statusCode, 200

    'should have data returned': (e, res, body)->
      assert.equal JSON.parse(res.body).success, true
      assert.isString JSON.parse(res.body).html

  'GET /api/view/getViewByName?name=index':
    topic: ()->
      request url + '/api/view/getViewByName?name=index', this.callback
      undefined

    'should respond with a 200 OK': (e, res, body)->
      assert.equal res.statusCode, 200

    'should have HTML returned': (e, res, body)->
      assert.equal    JSON.parse(res.body).success, true
      assert.isString JSON.parse(res.body).html

exports.testWebServerDockerViewPortEndpoints = vows.describe("Test Docker ViewPort Endpoints").addBatch

  ###
    Here we are getting one active container.  Its Id will be used to
    test container details and log methods, which are inline.
  ###
  'GET /api/view/getUpContainers':
    topic: ()->
      request url + '/api/view/getUpContainers', this.callback
      undefined

    'should respond with a 200 OK': (e, res, body)->
      assert.equal res.statusCode, 200

    'should have HTML returned': (e, res, body)->
      assert.equal    JSON.parse(res.body).success, true
      assert.isString JSON.parse(res.body).html

    'should have a containers array': (err, res, body)->
      body = JSON.parse(res.body)

      assert.isArray body.containers

    'should have at least one running container': (err, res, body)->
      body = JSON.parse(res.body)

      assert.isObject body.containers[0]
      assert.isString body.containers[0].Id

      containerId = body.containers[0].Id

    ', GET /api/view/getContainerDetails':
      topic: ()->
        request url + "/api/view/getContainerDetails?id=#{containerId}", this.callback
        undefined

      'should have no err': (err, res, body)->
        assert.isNull err

      'should respond with a 200 OK': (e, res, body)->
        assert.equal res.statusCode, 200

      'body can be parsed': (err, res, body)->
        console.log body
        body = JSON.parse(res.body)

      'should have HTML returned': (e, res, body)->
        assert.equal    JSON.parse(res.body).success, true
        assert.isString JSON.parse(res.body).html

      'html should contain container details': (err, res, body)->
        body = JSON.parse res.body

        containsId      = body.html.indexOf("Id")      >= 0

        assert.equal containsId, true

    ', GET /api/view/getContainerLogs':
      topic: ()->
        request url + "/api/view/getContainerLogs?id=#{containerId}", this.callback
        undefined

      'should respond with a 200 OK': (e, res, body)->
        assert.equal res.statusCode, 200

      'should have HTML returned': (e, res, body)->
        assert.equal    JSON.parse(res.body).success, true
        assert.isString JSON.parse(res.body).html

  'GET /api/view/getAllContainers':
    topic: ()->
      request url + '/api/view/getAllContainers', this.callback
      undefined

    'should respond with a 200 OK': (e, res, body)->
      assert.equal res.statusCode, 200

    'should have HTML returned': (e, res, body)->
      assert.equal    JSON.parse(res.body).success, true
      assert.isString JSON.parse(res.body).html

    'should have a containers array': (err, res, body)->
      body = JSON.parse(res.body)

      assert.isArray body.containers

  'GET /api/view/getAllImages':
    topic: ()->
      request url + '/api/view/getAllImages', this.callback
      undefined

    'should respond with a 200 OK': (e, res, body)->
      assert.equal res.statusCode, 200

    'should have HTML returned': (e, res, body)->
      assert.equal    JSON.parse(res.body).success, true
      assert.isString JSON.parse(res.body).html

exports.testWebServerMockedEndpoints = vows.describe("Test Mocked Endpoints").addBatch
  'GET /mock':
    topic: ()->
      request url + '/mock', this.callback
      undefined

    'should respond with a 200 OK': (e, res, body)->
      assert.equal res.statusCode, 200

    'should have mocked data returned': (e, res, body)->
      assert.equal JSON.parse(res.body).success, true

  'GET /api/random/testing':
    topic: ()->
      request url + '/api/random/testing', this.callback
      undefined

    'should respond with a 200 OK': (e, res, body)->
      assert.equal res.statusCode, 200

    'should have random returned': (e, res, body)->
      assert.equal JSON.parse(res.body).success, true
      assert.equal JSON.parse(res.body).random, 'testing'

  'GET /api/view/getViewByName?name=doesntExist':
    topic: ()->
      request url + '/api/view/getViewByName?name=doesntExist', this.callback
      undefined

    'should respond with a 200 OK': (e, res, body)->
      assert.equal res.statusCode, 200

    'should be able to parse body': (err, res, body)->
      JSON.parse(body)

    'should have an err object returned': (e, res, body)->
      assert.isObject JSON.parse(res.body).err

    'should say the template doesnt exist': (err, res, body)->
      response = JSON.parse(res.body).err.view

      assert.equal response.name, "doesntExist/body.jade"
      assert.equal response.ext, ".jade"