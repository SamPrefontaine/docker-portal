async   = require 'async'
ansi_up = require 'ansi_up'

removeFirstCharacter = (text, cb)->
  textArray = text.split("\n")
  newText   = ""

  eachRow = (row, rcb)->
    buf = new Buffer(row, 'UTF8')

    if buf.length <= 0
      rcb()
      return

    newText += buf.toString('UTF8', 8) + "\n"
    rcb()

  async.forEach textArray, eachRow, ()->

    cb(newText)

  return text

convertToHtml = (text, cb)->
  cb(ansi_up.ansi_to_html(text))

  return text

class ViewPort
  constructor: ()->
    @hasViewPort      = true
    @viewPort         = {}

  routeViewPort: ()->
    web  = @
    app  = @app

    # Keep this list updated.  It means we have tests for each of
    # the following viewport methods:
    @viewPort.methods = [
      "getViewByName",
      "getGlobalNavigation",
      "getCarouselForViewName",
      "getUpContainers",
      "getAllContainers",
      "getAllImages",
      "getContainerDetails",
      "getContainerLogs"
    ]

    app.get '/api/view/:method', (req, res)->
      if !req.query
        res.send { err: "No GET Query data defined" }
        return

      method = req.params.method

      switch method
        when "getViewByName"
          if !req.query.name then return res.send { err: "No name parameter provided in query data" }

          name = req.query.name

          app.render "#{name}/body.jade", { name: name, user: req.user || undefined }, (err, html)->
            return res.send { success: true, err: err, html: html }

        when "getGlobalNavigation"
          if !req.query.name then return res.send { err: "No name parameter provided in query data" }

          name = req.query.name

          app.render "globalNavigation.jade", { name: name, user: req.user || undefined }, (err, html)->
            return res.send { success: true, html: html, err: err }

        when "getCarouselForViewName"
          if !req.query.name then return res.send { err: "No name parameter provided in query data" }

          name = req.query.name

          app.render "carousel.jade", { name: name, user: req.user || undefined }, (err, html)->
            return res.send { success: true, err: err, html: html }

        when "getUpContainers"
          web.getUpContainers (err, dockerRes, body)=>
            if err
              console.log err

            else
              containers = JSON.parse(body)

              app.render "upcontainers/body.jade", { name: 'containers', user: req.user || undefined, containers: containers }, (err, html)->
                return res.send { success: true, err: err, html: html, containers: containers }

        when "getAllContainers"
          web.getAllContainers (err, dockerRes, body)=>
            if err
              console.log err

            else
              containers = JSON.parse(body)

              app.render "allcontainers/containers.jade", { name: 'containers', user: req.user || undefined, containers: containers }, (err, html)->
                return res.send { success: true, err: err, html: html, containers: containers }

        when "getAllImages"
          web.getAllImages (err, dockerRes, body)=>
            if err
              console.log err

            else
              images = JSON.parse(body)

              for id of images
                images[id].CreatedString = new Date(images[id].Created * 1000)
                createLen = images[id].CreatedString.toString().length

                images[id].CreatedString = images[id].CreatedString.toString().substr(0, createLen - 15)

              app.render "allimages/body.jade", { name: 'images', user: req.user || undefined, images: images }, (err, html)->
                return res.send { success: true, err: err, html: html, images: images }

        when "getHostDetails"
          web.getHostDetails (err, os, process)->
            if err
              console.log err

            else
              app.render "about/host.jade", { user: req.user || undefined, os: os, process: process }, (err, html)->
                return res.send { success: true, err: err, html: html, os: os }

        when "doRestart"
          if !req.query.id then return res.send { err: "No id parameter provided in query data" }

          id = req.query.id

          web.getContainerDetails id, (err, dockerRes, body)=>
            if err
              console.log err

            else

              details = JSON.parse(body)
              util = require 'util'

              app.render "container/restart.jade", { name: 'containers', user: req.user || undefined, details: details }, (err, html)->
                return res.send { success: true, err: err, html: html, details: details }

        when "doDelete"
          if !req.query.id then return res.send { err: "No id parameter provided in query data" }

          id = req.query.id

          web.getContainerDetails id, (err, dockerRes, body)=>
            if err
              console.log err

            else
              details = JSON.parse(body)

              app.render "container/delete.jade", { name: 'containers', user: req.user || undefined, details: details }, (err, html)->
                return res.send { success: true, err: err, html: html, details: details }

        when "doStart"
          if !req.query.id then return res.send { err: "No id parameter provided in query data" }

          id = req.query.id

          web.getContainerDetails id, (err, dockerRes, body)=>
            if err
              console.log err

            else
              details = JSON.parse(body)

              app.render "container/start.jade", { name: 'containers', user: req.user || undefined, details: details }, (err, html)->
                return res.send { success: true, err: err, html: html, details: details }

        when "doStop"
          if !req.query.id then return res.send { err: "No id parameter provided in query data" }

          id = req.query.id

          web.getContainerDetails id, (err, dockerRes, body)=>
            if err
              console.log err

            else
              details = JSON.parse(body)

              app.render "container/stop.jade", { name: 'containers', user: req.user || undefined, details: details }, (err, html)->
                return res.send { success: true, err: err, html: html, details: details }

        when "getContainerDetails"
          if !req.query.id then return res.send { err: "No id parameter provided in query data" }

          id = req.query.id

          web.getContainerDetails id, (err, dockerRes, body)=>
            if err
              console.log err

            else

              details = JSON.parse(body)
              util = require 'util'

              app.render "container/details.jade", { name: 'containers', user: req.user || undefined, details: details }, (err, html)->
                return res.send { success: true, err: err, html: html, details: details }

        when "getContainerLogs"
          if !req.query.id then return res.send { err: "No id parameter provided in query data" }

          id = req.query.id

          web.getContainerLogs id, (err, body)=>
            if err
              console.log err

            else
              convertToHtml body, (logs)->
                removeFirstCharacter logs, (logs)->
                  web.getContainerDetails id, (err, dockerRes, body)=>
                    if err
                      console.log err

                    else

                      details = JSON.parse(body)
                      app.render "container/logs.jade", { name: 'containers', user: req.user || undefined, logs: logs, details: details }, (err, html)->
                        return res.send { success: true, err: err, html: html, logs: logs, details: details }

    return @

module.exports = ViewPort