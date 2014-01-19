vows   = require 'vows'
assert = require 'assert'
Docker = require '../lib/Docker'

settings = require '../settings.coffee'

# Valid container for testing getContainerDetails
containerId = ""

tempContainerId = ""


docker = {}

exports.testDockerClass = vows.describe("Docker Class").addBatch
  'Create an instance of Docker class':
    topic: ()->
      docker = new Docker()

      return docker

    'we get a docker instance back': (docker)->
      assert.isObject docker

    'we get our instance methods': (docker)->

      for id of docker
        if id != "hasDocker"
          assert.isFunction docker[id]

          console.log "\tdocker.#{id}()"

exports.testDockerMethods = vows.describe("docker instance methods").addBatch
  "instance method getAllContainers":
    topic: ()->
      docker.getAllContainers(this.callback)
      undefined

    'we get no err': (err, res, data)->
      assert.isNull err

    'status code should be 200': (err, res, data)->
      assert.equal res.statusCode, 200

    'we can parse the response data': (err, res, data)->
      JSON.parse(data)

    'response should be an array': (err, res, data)->
      assert.isArray JSON.parse(data)


  "instance method getUpContainers":
    topic: ()->
      docker.getUpContainers(this.callback)
      undefined

    'we get no err and data back': (err, res, data)->
      assert.isNull err

    'we have at least one running container to get details for': (err, res, data)->
      lengthTruth = JSON.parse(data).length > 0
      assert.equal lengthTruth, true

    'we can get the ID of a running container': (err, res, data)->
      containers = JSON.parse(data)

      assert.isString containers[0].Id

      containerId = containers[0].Id

    ", getContainerDetails":
      topic: ()->
        docker.getContainerDetails(containerId, this.callback)
        undefined

      'we get no err': (err, res, data)->
        assert.isNull err

      'we get a status of 200': (err, res, data)->
        assert.equal res.statusCode, 200

      'we can parse the response data': (err, res, data)->
        JSON.parse(data)

      'data is an object': (err, res, data)->
        data = JSON.parse(data)
        assert.isObject data

      'data has important keys': (err, res, data)->
        data = JSON.parse(data)

        assert.isString data.ID
        assert.isString data.Created
        assert.isString data.Path
        assert.isArray data.Args
        assert.isString data.Config.Hostname
        assert.isString data.Image

    ", getContainerLogs":
      topic: ()->
        docker.getContainerLogs(containerId, this.callback)
        undefined

      'we get no err and data back': (err, data)->
        assert.isNull err

      'we get useful data': (err, data)->
        assert.isString data

  "instance method getAllImages":
    topic: ()->
      docker.getAllImages(this.callback)
      undefined

    'we get no err': (err, res, data)->
      assert.isNull err

    'we get a status code of 200': (err, res, data)->
      assert.equal res.statusCode, 200

    'we can parse the data': (err, res, data)->
      JSON.parse(data)

    'we get an array response': (err, res, data)->
      assert.isArray JSON.parse(data)


  ###
    Here we are testing the creation and deletion of a container.
    First we create a container with the name "vowsTest1234",
    then we delete it, inline.
  ###
  "instance method createContainer":
    topic: ()->
      req =
        Cmd: ["/bin/date"]
        Image: "ubuntu"
        Hostname: ""
        AttachStderr: true
        AttachStdin: false
        AttachStdout: true
        Memory: 0
        MemorySwap: 0
        PortSpec: null
        Volumes:
          "/tmp": {}
        Privileged: false
        StdinOnce: false
        Tty: false
        User: ""
        WorkingDir: ""

      docker.createContainer("vowsTest1234", req, this.callback)
      undefined

    'we get no err': (err, res, body)->
      assert.isNull err

    'we get 201': (err, res, body)->
      assert.equal res.statusCode, 201

    'we get an Id back': (err, res, body)->
      body = JSON.parse(body)

      assert.isString body.Id

      tempContainerId = body.Id

    ", deleteContainer":
      topic: ()->
        docker.deleteContainer(tempContainerId, this.callback)
        undefined

      'we get no err': (err, res, body)->
        assert.isNull err

      'we get 204': (err, res, body)->
        assert.equal res.statusCode, 204