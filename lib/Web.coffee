SuperClass = require './SuperClass.coffee'
Security   = require './Security.coffee'
ViewPort   = require './ViewPort.coffee'
Docker     = require './Docker.coffee'

class Controller
  constructor: ()->
    @hasController = true

    @controller = {}

  setupControllers: ()->
    # we will add controllers, later
    @app.get '/', (req, res)=>

      res.render 'index', { title: "docker-portal" }

class Events
  constructor: ()->
    @hasEvents = true

  getEvents: ()->
    return []

class Web extends SuperClass
  @include Controller
  @include Events
  @include Security
  @include ViewPort
  @include Docker

  constructor: (@settings)->
    @cluster = require 'cluster'

    Controller.call @
    Events.call     @
    Security.call   @
    ViewPort.call   @
    Docker.call     @

  configure: ()->
    express = require('express')
    app     = express()
    redis   = require('connect-redis')(express)

    @http    = require('http')
    @path    = require('path')

    if ('development' is app.get('env'))
      app.use(express.errorHandler())


    ###
      Setup our client assets.  Here we use asset-rack, which is cluster aware.
      This will let us create coffee-scripts and link to them as compiled sources
      in our templates with !{assets.tag("/location/to/file.js")}.  This will
      create a unique in-memory compile of the asset, which may be compressed
      if desired.
    ###
    rack = require('asset-rack')
    assets = new rack.AssetRack([
      new rack.DynamicAssets({
        type: rack.SnocketsAsset,
        urlPrefix: "/js",
        dirname: './assets/js',
        options: {
          compress: @settings.assets.compress
        }
      }),
      new rack.StaticAssets({
        dirname: './assets/css',
        urlPrefix: "/css"
      })
    ])

    @sessionStore = new redis()

    app.set('port', process.env.PORT || 3000)
    app.set('views', @settings.scriptPath + '/views')
    app.set('view engine', 'jade')
    app.use(express.favicon())
    app.use(express.logger('dev'))
    app.use(express.bodyParser())
    app.use(express.methodOverride())
    app.use(express.cookieParser(@settings.session.cookie))
    app.use(express.session({ secret: @settings.session.secret, store: @sessionStore }))
    app.use(assets)
    app.use(app.router)
    app.use(express.static(@path.join(@settings.scriptPath, 'public')))

    @app = app

    # route the viewPort
    @routeViewPort()

    # route the docker endpoints
    @routeDockerEndpoints()

    @configured = true
    return @

  log: (msg)->
    if @muteOutput
      return

    if !@cluster.isMaster
      console.log "worker #{@cluster.worker.id}: #{msg}"
    else
      console.log msg

    return @

  createServer: ()->
    @setupControllers()

    @listener = @http.createServer(@app).listen @app.get('port'), ()=>
      @log('Express server listening on port ' + @app.get('port'))
      @listening = true

    return @

  isPortInUse: ()->
    return false

module.exports = Web
