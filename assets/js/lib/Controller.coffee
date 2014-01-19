class Controller

  constructor: ()->
    @view = 'index'

    @displayView()
    @displayGlobalNavgation()
    @addGlobalClickEvents()
    @displayCarousel()

    @addContainerClickEvents()

  displayView: ()->
    controller = @
    $.ajax
      url: '/api/view/getViewByName'
      data:
        name: @view
      success: (data)->
        if !data.html
          alert('unable to load view html for ' + controller.view)

        if data.err
          console.log data.err

        $("#bodyDiv").hide().html(data.html).fadeIn('slow')
      dataType: 'json'

    return @

  getUpContainers: (cb)->
    $("a[data-name='containers']").parent().addClass('active')

    controller = @
    $.ajax
      url: '/api/view/getUpContainers'
      success: (data)->
        if !data.html
          alert('unable to load view html for getUpContainers')
        else
          cb(data)
      dataType: 'json'

    return @

  getAllContainers: (cb)->
    $("a[data-name='allcontainers']").parent().addClass('active')

    controller = @
    $.ajax
      url: '/api/view/getAllContainers'
      success: (data)->
        if !data.html
          alert('unable to load view html for getAllContainers')
        else
          cb(data)
      dataType: 'json'

    return @

  getAllImages: (cb)->
    $("a[data-name='images']").parent().addClass('active')

    controller = @
    $.ajax
      url: '/api/view/getAllImages'
      success: (data)->
        if !data.html
          alert('unable to load view html for getAllImages')
        else
          cb(data)

      dataType: 'json'

    return @

  displayGlobalNavgation: ()->
    $.ajax
      url: '/api/view/getGlobalNavigation'
      data:
        name: @view
      success: (data)->
        $("#globalNavigationDiv").html data.html
      dataType: 'json'

    return @

  displayCarousel: ()->
    $.ajax
      url: '/api/view/getCarouselForViewName'
      data:
        name: @view
      success: (data)->
        $("#carousel").hide().html(data.html).fadeIn('slow')
      dataType: 'json'

    return @

  addGlobalClickEvents: ()->
    controller = @

    $("#bodyDiv").on 'click', 'a', (e)->
      component = $(this).data("component")
      method    = $(this).data("method")

      switch component
        when "view"
          switch method
            when "getViewByName"
              $("#globalNavigationDiv a").parent().removeClass('active')

              if $("#carousel").is(":visible")
                $("#carousel").fadeOut('slow')

              controller.view = $(this).data("name")
              controller.displayView()

              if $(this).data("name") is "index"
                $("#carousel").fadeIn('slow')

              if $(this).data("name") is "about"
                $("#navAboutLink").parent().addClass('active')

        when "containers"
          switch method
            when "getContainerDetails"
              id = $(this).data("id")
              window.controller.getContainerDetails id, (data)->
                $("#dockerContainersDiv").html(data.html)

            when "doRestart"
              id = $(this).data("id")
              window.controller.doRestart id, (data)->
                $("#dockerContainersDiv").html(data.html)

            when "doDelete"
              id = $(this).data("id")
              window.controller.doDelete id, (data)->
                $("#dockerContainersDiv").html(data.html)

            when "doStop"
              id = $(this).data("id")
              window.controller.doStop id, (data)->
                $("#dockerContainersDiv").html(data.html)

            when "doStart"
              id = $(this).data("id")
              window.controller.doStart id, (data)->
                $("#dockerContainersDiv").html(data.html)

            when "getContainerLogs"
              id = $(this).data("id")
              $("li[data-group='containerNav']").removeClass('active')
              $(this).parent().addClass('active')
              window.controller.getContainerLogs id, (data)->
                $("#dockerContainersDiv").html(data.html)

    $("#bodyDiv").on 'click', 'button', (e)->
      component = $(this).data("component")
      method    = $(this).data("method")

      switch component
        when "containers"
          id = $(this).data("id")
          $(this).attr('disabled', 'disabled')

          switch method
            when "getContainerDetails"
              window.controller.getContainerDetails id, (data)->
                $("#dockerContainersDiv").html(data.html)

            when "createContainer"

              request =
                image    : $("#startContainerImage>option:selected").data("id")
                hostname : $("#startContainerHostname").val()
                cmd      : $("#startContainerCommand").val()
                workDir  : $("#startContainerWorkDir").val()
                ports    : $("#startContainerPorts").val()
                env      : $("#startContainerEnv").val()
                name     : $("#startContainerName").val() || (Math.random() * 10000).toFixed(2)
                ports    : $("#startContainerPorts").val()
                ip       : $("#startContainerIp").val()
                volumes  : $("#startContainerVolumes").val()

              $.ajax
                url: '/api/docker/create'
                data: request
                success: (data)->
                  if data.status != 201
                    alert("Unable to create container, status is #{data.status}")
                    window.controller.getAllContainers (data)->
                      $("#dockerContainersDiv").html(data.html)
                      $("li [data-name='containers']").parent().addClass('active')
                  else
                    json = JSON.parse(data.body)
                    window.controller.getContainerDetails json.Id, (templateData)->
                      $("#dockerContainersDiv").html(templateData.html)
                dataType: 'json'

            when "startContainer"
              $.ajax
                url: '/api/docker/start'
                data:
                  id: id
                  options:
                    Binds: $("#runContainerBinds").val()
                    PortBindings: $("#runContainerPortBindings").val()
                success: (data)->
                  if data.status != 204
                    alert("Unable to start container, status is #{data.status}")

                  window.controller.getContainerDetails id, (templateData)->
                    $("#dockerContainersDiv").html(templateData.html)
                dataType: 'json'

            when "stopContainer"
              $.ajax
                url: '/api/docker/stop'
                data:
                  id: id
                success: (data)->
                  if data.status != 204
                    alert("Unable to stop container, status is #{data.status}")

                  window.controller.getContainerDetails id, (templateData)->
                    $("#dockerContainersDiv").html(templateData.html)

                dataType: 'json'

            when "restartContainer"
              $.ajax
                url: '/api/docker/restart'
                data:
                  id: id
                success: (data)->
                  if data.status != 204
                    alert("Unable to restart container, status is #{data.status}")

                  window.controller.getContainerDetails id, (templateData)->
                    $("#dockerContainersDiv").html(templateData.html)
                dataType: 'json'

            when "deleteContainer"

              $.ajax
                url: '/api/docker/delete'
                data:
                  id: id
                success: (data)->
                  if data.status != 204
                    alert("Unable to delete container, status is #{data.status}")

                  window.controller.getAllContainers (data)->
                    $("#dockerContainersDiv").html(data.html)
                    $("li [data-name='containers']").parent().addClass('active')

                dataType: 'json'


    $("#carousel").on 'click', 'a', (e)->
      component = $(this).data("component")
      method    = $(this).data("method")

      switch component
        when "view"

          switch method
            when "getViewByName"
            # reset the active nav links
              $("#globalNavigationDiv a").parent().removeClass('active')

              # display the new template
              controller.view = $(this).data("name")
              controller.displayView()

              if $("#carousel").is(":visible")
                $("#carousel").fadeOut('slow')

              if $(this).data("name") is "index"
                $("#carousel").fadeIn('slow')

              if $(this).data("name") is "about"
                $("#navAboutLink").parent().addClass('active')

              if $(this).data("name") is "knowledge"
                $("#navKnowledgeLink").parent().addClass('active')

    $("#globalNavigationDiv").on 'click', 'a', (e)->
      component = $(this).data("component")
      method    = $(this).data("method")

      switch component
        when "view"

          switch method
            when "getViewByName"
              # reset the active nav links
              $("a").parent().removeClass('active')
              $(this).parent().addClass('active')

              # display the new template
              controller.view = $(this).data("name")
              controller.displayView()

              if $("#carousel").is(":visible")
                $("#carousel").hide()

              if $(this).data("name") is "index"
                $("#carousel").fadeIn('slow')

    return @

  addContainerClickEvents: ()->
    controller = @

    return @

  getHostDetails: (cb)->
    controller = @

    $.ajax
      url: '/api/view/getHostDetails'
      success: (data)->
        cb(data)
      dataType: 'json'

    return @

  doStop: (id, cb)->
    controller = @
    $.ajax
      url: '/api/view/doStop'
      data:
        id: "#{id}"
      success: (data)->
        if !data.html
          alert('unable to load doStop prompt for container')
        else
          cb(data)
      dataType: 'json'

    return @

  doStart: (id, cb)->
    controller = @
    $.ajax
      url: '/api/view/doStart'
      data:
        id: "#{id}"
      success: (data)->
        if !data.html
          alert('unable to load doStart prompt for container')
        else
          cb(data)
      dataType: 'json'

    return @

  doDelete: (id, cb)->
    controller = @
    $.ajax
      url: '/api/view/doDelete'
      data:
        id: "#{id}"
      success: (data)->
        if !data.html
          alert('unable to load doDelete prompt for container')
        else
          cb(data)
      dataType: 'json'

    return @

  doRestart: (id, cb)->
    controller = @
    $.ajax
      url: '/api/view/doRestart'
      data:
        id: "#{id}"
      success: (data)->
        if !data.html
          alert('unable to load doRestart prompt for container')
        else
          cb(data)
      dataType: 'json'

    return @

  getContainerDetails: (id, cb)->
    controller = @
    $.ajax
      url: '/api/view/getContainerDetails'
      data:
        id: "#{id}"
      success: (data)->
        if !data.html
          alert('unable to load details for container')
        else
          cb(data)
      dataType: 'json'

    return @

  getContainerLogs: (id, cb)->
    controller = @
    $.ajax
      url: '/api/view/getContainerLogs'
      data:
        id: "#{id}"
      success: (data)->
        if !data.html
          alert('unable to load logs from container')
        else
          cb(data)
      dataType: 'json'

    return @

window.Controller = Controller