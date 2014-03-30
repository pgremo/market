express = require 'express'
routes = require './routes'
http = require 'http'
path = require 'path'
rest = require 'rest'
xml2js = require 'xml2js'
util = require 'util'
url = require 'url'
promise = require('es6-promise').Promise
querystring = require 'querystring'
types = require './data/types'
_ = require 'underscore'
numeral = require 'numeral'

server_port = process.env.PORT || 3000

parseString = new xml2js.Parser({explicitArray: false, mergeAttrs: true}).parseString

groups = promise.all(_.map(_.values(_.groupBy(types, (x) -> x.groupName)), (x) ->
    priceQuery = {typeid : x.map((y) -> y.typeID), regionlimit : '10000002'}
    priceUrl = "http://api.eve-central.com/api/marketstat?#{querystring.stringify priceQuery}"

    rest(priceUrl).then (res) ->
      items = []
      parseString res.entity, (err, result) ->
        items = x.map (y) ->
          _.extend {marketstat : _.find(result.evec_api.marketstat.type, (z) -> z.id == y.typeID)}, y
      {category: items[0].categoryName, name: items[0].groupName, types: items}
  )
)

app = express()

app.locals.numeral = numeral

app
  .set 'port', server_port
  .set 'views', path.join(__dirname, 'views')
  .set 'view engine', 'jade'
  .use express.favicon(path.join(__dirname, 'public/images/favicon.ico'))
  .use express.logger('dev')
  .use express.json()
  .use express.urlencoded()
  .use express.methodOverride()
  .use app.router
  .use require('less-middleware')(path.join(__dirname, 'public'))
  .use require('coffee-middleware')({ src: path.join(__dirname, 'public'), compress: true })
  .use express.static(path.join(__dirname, 'public'))

if 'development' == app.get('env')
  app.use express.errorHandler()

app.get '/', (req, res) ->
  groups.then (x) ->
    req.groups = x
    routes.index req, res

http.createServer(app).listen server_port, () ->
  console.log "Express server listening on port #{ app.get 'port' }"
