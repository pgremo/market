config = require './config'
express = require 'express'
path = require 'path'
numeral = require 'numeral'
moment = require 'moment'
packageInfo = require './package.json'
pricing = require './data/pricing'
routes = require './routes'

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
  .get routes.index
  .post routes.price
app.use '/', router

app.listen port, -> console.log "Express server listening on port #{port}"
