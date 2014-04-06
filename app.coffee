require 'es6-shim'
config = require('./config').config
express = require 'express'
http = require 'http'
path = require 'path'
rest = require 'rest'
xml2js = require 'xml2js'
util = require 'util'
url = require 'url'
querystring = require 'querystring'
_ = require 'underscore'
numeral = require 'numeral'
moment = require 'moment'
packageInfo = require './package.json'
types = require './data/types'
regions = require './data/regions'

parser = new xml2js.Parser
  explicitArray: false
  mergeAttrs: true

parseString = (x) ->
  new Promise (resolve, reject) ->
    parser.parseString x, (err, result) ->
      if result?
        resolve result
      else
        reject err

Array::flatten = () -> _.flatten this
Array::groupBy = (x) -> _.groupBy this, x
Array::indexBy = (x) -> _.indexBy this, x

regionID = regions.find((x) -> x.regionName == config.regionName).regionID

groups = for key, xs of types.groupBy 'groupName'
  do (key, xs) ->
    priceUrl = url.parse config.pricingURL
    priceUrl.search = querystring.stringify {typeid : y.typeID for y in xs, regionlimit : regionID}
    rest url.format priceUrl
      .then (res) ->
        parseString res.entity
      .then (res) ->
        items = []
        for x in xs
          for y in res.evec_api.marketstat.type
            if x.typeID is y.id
              items.push {info: x, marketstat: y}
        {category: xs[0].categoryName, name: xs[0].groupName, types: items}

groupsByName = Promise.all groups

pricedTypesById = groupsByName
  .then (x) ->
    x
      .map (y) -> y.types
      .flatten()
      .indexBy (y) -> y.info.typeID

server_port = process.env.PORT or config.port

app = express()

app.locals.numeral = numeral
app.locals.moment = moment
app.locals.packageInfo = packageInfo
app.locals.pricingLoaded = new Date()
app.locals.pricingRegion = config.regionName

app
  .set 'port', server_port
  .set 'views', path.join __dirname, 'views'
  .set 'view engine', 'jade'
  .use express.favicon(path.join __dirname, 'public/images/favicon.ico')
  .use express.logger 'dev'
  .use express.json()
  .use express.urlencoded()
  .use express.methodOverride()
  .use app.router
  .use require('less-middleware') path.join(__dirname, 'public')
  .use require('coffee-middleware')
    src: path.join __dirname, 'public'
    compress: true
  .use express.static path.join __dirname, 'public'

if 'development' == app.get('env')
  app.use express.errorHandler()

app.get '/', (req, res) ->
  groupsByName.then (x) ->
    res.render 'index', groups: x

app.post '/', (req, res) ->
  pricedTypesById.then (ipts) ->
    priced = for typeid, num of req.body when num != ''
      [type, count] = [ipts[typeid], parseFloat num]
      {type: type, count: count, total: count * type.marketstat.sell.avg}
    res.render 'index_post',
      count: priced.reduce((seed, x) ->
          seed + x.count
        0),
      total: priced.reduce((seed, x) ->
          seed + x.total
        0),
      types: priced

http
  .createServer app
  .listen server_port, () ->
    console.log "Express server listening on port #{ server_port }"
