config = require('./config').config
express = require 'express'
routes = require './routes'
market = require './routes/market'
http = require 'http'
path = require 'path'
rest = require 'rest'
xml2js = require 'xml2js'
util = require 'util'
url = require 'url'
promise = require('es6-promise').Promise
querystring = require 'querystring'
types = require './data/types'
regions = require './data/regions'
_ = require 'underscore'
numeral = require 'numeral'
moment = require 'moment'
packageInfo = require './package.json'

parseString = new xml2js.Parser({explicitArray: false, mergeAttrs: true}).parseString

regionID = _.find(regions, (x) -> x.regionName == config.regionName).regionID
groups = promise.all(_.map(_.values(_.groupBy(types, (x) -> x.groupName)), (x) ->
    priceQuery = {typeid : x.map((y) -> y.typeID), regionlimit : regionID}
    priceUrl = "http://api.eve-central.com/api/marketstat?#{querystring.stringify priceQuery}"

    rest(priceUrl).then (res) ->
      items = []
      parseString res.entity, (err, result) ->
        items = x.map (y) ->
          _.extend {marketstat : _.find(result.evec_api.marketstat.type, (z) -> z.id == y.typeID)}, y
      {category: items[0].categoryName, name: items[0].groupName, types: items}
  )
)

indexedPricedTypes = groups.then (x) ->
  _.object(_.map(_.flatten(_.map(x, (y) -> y.types)), (y) -> [y.typeID, y]))

server_port = process.env.PORT || config.port

app = express()

app.locals.numeral = numeral
app.locals.moment = moment
app.locals.packageInfo = packageInfo
app.locals.pricingLoaded = new Date()
app.locals.pricingRegion = config.regionName

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
    routes.index req, res, x

app.post '/', (req, res) ->
  indexedPricedTypes.then (ipts) ->
    priced = _.map(_.filter(_.pairs(req.body), (x) -> x[1] != ''), (x) ->
      type = ipts[x[0]]
      price = type.marketstat.sell.avg
      count = parseFloat(x[1])
      {type: type, count: count, total: count * price})
    result = {
      count: _.reduce(priced, (seed, x) ->
          seed + x.count
        0),
      total: _.reduce(priced, (seed, x) ->
          seed + x.total
        0),
      types: priced
    }
    console.log 'done calculating'
    market.contractDetail req, res, result

http.createServer(app).listen server_port, () ->
  console.log "Express server listening on port #{ app.get 'port' }"
