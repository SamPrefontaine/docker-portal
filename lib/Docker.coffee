request = require 'request'
settings = require '../settings'

url = settings.docker.tcpHost

class Docker
  constructor: ()->
    @hasDocker = true

  routeDockerEndpoints: ()=>
    web = @
    app = @app

    app.get '/api/docker/:method', (req, res)->

      method = req.params.method

      switch method
        when "create"
          options =
            Cmd: req.query.cmd.split(" ")
            Image: req.query.image
            Hostname: req.query.hostname
            Env: req.query.env.split(",")
            AttachStderr: true
            AttachStdin: false
            AttachStdout: true
            Memory: 0
            MemorySwap: 0
            PortSpecs: null
            ExposedPorts: JSON.parse(req.query.ports) || {}
            Volumes: JSON.parse(req.query.volumes) || {}
            Privileged: false
            StdinOnce: false
            Tty: false
            User: ""
            WorkingDir: req.query.workDir

          web.createContainer req.query.name, options, (err, response, body)->

            res.send { success: true, query: req.query, method: method, status: response.statusCode, body: body }

        when "restart"
          web.restartContainer req.query.id, (err, response, body)->
            if err
              console.log err

            res.send { success: true, query: req.query, method: method, status: response.statusCode }

        when "start"
          options =
            Binds: JSON.parse(req.query.options.Binds) || []
            PortBindings: JSON.parse(req.query.options.PortBindings) || {}

          web.startContainer req.query.id, options, (err, response, body)->
            if err
              console.log err

            res.send { success: true, query: req.query, method: method, status: response.statusCode }

        when "stop"
          web.stopContainer req.query.id, (err, response, body)->
            if err
              console.log err

            res.send { success: true, query: req.query, method: method, status: response.statusCode }

        when "delete"
          web.deleteContainer req.query.id, (err, response, body)->
            if err
              console.log err

            res.send { success: true, query: req.query, method: method, status: response.statusCode }


    return @

  getHostDetails: (cb)->
    os = require 'os'

    cb(null, os, process)
    return @

  getAllContainers: (cb)->
    processRequest = (err, res, body)->

      cb(err, res, body)

    config =
      headers :
        "Content-Type" : "application/json"
      url : "#{url}/containers/json?all=1"

    request.get(config, processRequest)

    return @

  getUpContainers: (cb)->
    processRequest = (err, res, body)->
      cb(err, res, body)

    config =
      headers :
        "Content-Type" : "application/json"
      url : "#{url}/containers/json?all=0"

    request.get(config, processRequest)

    return @

  getAllImages: (cb)->
    processRequest = (err, res, body)->
      cb(err, res, body)

    config =
      headers :
        "Content-Type" : "application/json"
      url : "#{url}/images/json?all=0"

    request.get(config, processRequest)

    return @

  getContainerDetails: (id, cb)->
    processRequest = (err, res, body)->
      cb(err, res, body)

    config =
      headers :
        "Content-Type" : "application/json"
      url : "#{url}/containers/#{id}/json"

    request.get(config, processRequest)

    return @

  getContainerLogs: (id, cb)->
    processRequest = (err, res, body)->
      cb(err, body)

    config =
      headers :
        "Content-Type" : "application/json"
      url : "#{url}/containers/#{id}/attach?logs=1&stream=0&stdout=1&stderr=1"

    request.post(config, processRequest)

    return @

  createContainer: (name, req, cb)->
    processRequest = (err, res, body)->
      cb(err, res, body)

    config =
      headers :
        "Content-Type" : "application/json"
      url : "#{url}/containers/create?name=#{name}"
      body: JSON.stringify(req)

    request.post(config, processRequest)

  deleteContainer: (id, cb)->
    processRequest = (err, res, body)->
      cb(err, res, body)

    config =
      headers :
        "Content-Type" : "application/json"
      url : "#{url}/containers/#{id}?v=1"

    request.del(config, processRequest)

  startContainer: (id, options, cb)->
    processRequest = (err, res, body)->
      cb(err, res, body)

    config =
      headers :
        "Content-Type" : "application/json"
      url : "#{url}/containers/#{id}/start"
      body: JSON.stringify(options)

    request.post(config, processRequest)

  restartContainer: (id, cb)->
    processRequest = (err, res, body)->
      cb(err, res, body)

    config =
      headers :
        "Content-Type" : "application/json"
      url : "#{url}/containers/#{id}/restart?t=15"

    request.post(config, processRequest)

  stopContainer: (id, cb)->
    processRequest = (err, res, body)->
      cb(err, res, body)

    config =
      headers :
        "Content-Type" : "application/json"
      url : "#{url}/containers/#{id}/stop?t=45"

    request.post(config, processRequest)

module.exports = Docker
