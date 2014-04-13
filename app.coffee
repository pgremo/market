require 'es6-shim'
config = require './config'
express = require 'express'
http = require 'http'
path = require 'path'
util = require 'util'
_ = require 'underscore'
require './array'
numeral = require 'numeral'
moment = require 'moment'
packageInfo = require './package.json'
types = require './data/types'
regions = require './data/regions'
pricing = require './data/pricing'

server_port = process.env.PORT or config.port

app = express()

app.locals.numeral = numeral
app.locals.moment = moment
app.locals.packageInfo = packageInfo
app.locals.pricingLoaded = pricing.pricingDate
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
  pricing.groupsByName().then (x) ->
    res.render 'index', groups: x

app.post '/', (req, res) ->
  pricing.pricedTypesById().then (ipts) ->
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
