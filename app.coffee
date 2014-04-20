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

port = process.env.PORT or config.port

app = express()

app.locals.numeral = numeral
app.locals.moment = moment
app.locals.packageInfo = packageInfo
app.locals.pricingLoaded = pricing.pricingDate
app.locals.pricingRegion = config.regionName

app
  .set 'views', path.join __dirname, 'views'
  .set 'view engine', 'jade'
  .use require('static-favicon') path.join __dirname, 'public/images/favicon.ico'
  .use require('morgan') 'dev'
  .use require('body-parser')()
  .use require('method-override')()
  .use require('less-middleware') path.join(__dirname, 'public')
  .use require('coffee-middleware')
    src: path.join __dirname, 'public'
    compress: true
  .use express.static path.join __dirname, 'public'

if process.env.DEBUG
  app.use require('errorhandler')()

router = express.Router()

router.route '/'
  .get (req, res) ->
    pricing.groupsByName()
      .then (x) ->
        res.render 'index', groups: x
      .catch (err) -> console.log err

  .post (req, res) ->
    pricing.pricedTypesById()
      .then (ipts) ->
        priced = for typeid, num of req.body when num != ''
          [type, count] = [ipts[typeid], parseFloat num]
          {type: type, count: count, total: count * type.marketstat.sell.avg}
        res.render 'index_post',
          count: (priced
            .map (x) -> x.count
            .reduce (seed, x) -> seed + x)
          total: (priced
            .map (x) -> x.total
            .reduce (seed, x) -> seed + x)
          types: priced
      .catch (err) -> console.log err

app.use '/', router

app.listen port, () -> console.log "Express server listening on port #{port}"
