config = require('./config').config
express = require 'express'
http = require 'http'
path = require 'path'
rest = require 'rest'
xml2js = require 'xml2js'
util = require 'util'
url = require 'url'
Promise = require('es6-promise').Promise
querystring = require 'querystring'
types = require './data/types'
regions = require './data/regions'
_ = require 'underscore'
numeral = require 'numeral'
moment = require 'moment'
packageInfo = require './package.json'

parser = new xml2js.Parser({explicitArray: false, mergeAttrs: true})
parseString = (x) ->
  new Promise (resolve, reject) ->
    parser.parseString x, (err, result) ->
      if result?
        resolve result
      else
        reject err

_.mixin {
  join: (xs, ys, xf, yf, trans) ->
    result = []
    for x in xs
      xk = xf x
      for y in ys
        if xk == yf y
          result.push trans(x, y)
    result
  fmap: (xs, f) ->
    _.flatten _.map(xs, f)
  fpluck: (xs, property) ->
    _.flatten _.pluck(xs, property)
  }

regionID = _.find(regions, (x) -> x.regionName == config.regionName).regionID
groups = Promise.all(_.map(_.values(_.groupBy(types, 'groupName')), (x) ->
    priceUrl = url.parse config.pricingURL
    priceUrl.search = querystring.stringify {typeid : _.pluck(x, 'typeID'), regionlimit : regionID}

    rest(url.format priceUrl)
      .then (res) ->
        parseString res.entity
      .then (res) ->
        items = _.join x, res.evec_api.marketstat.type, _.property('typeID'), _.property('id'), ((x, y) -> {marketstat: y, info: x})
        {category: items[0].info.categoryName, name: items[0].info.groupName, types: items}
  )
)

indexedPricedTypes = groups.then (x) ->
  _.indexBy _.flatten(_.map(x, (y) -> y.types)),
    (y) ->
      y.info.typeID


server_port = process.env.PORT or config.port

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
    res.render 'index', { groups: x }

app.post '/', (req, res) ->
  indexedPricedTypes.then (ipts) ->
    priced = _.map(_.filter(_.pairs(req.body), (x) -> x[1] != ''), (x) ->
      type = ipts[x[0]]
      count = parseFloat x[1]
      {type: type, count: count, total: count * type.marketstat.sell.avg})
    res.render 'index_post', {
      count: _.reduce(priced, (seed, x) ->
          seed + x.count
        0),
      total: _.reduce(priced, (seed, x) ->
          seed + x.total
        0),
      types: priced
    }

http.createServer(app).listen server_port, () ->
  console.log "Express server listening on port #{ app.get 'port' }"
