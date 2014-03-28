express = require 'express'
routes = require './routes'
http = require 'http'
path = require 'path'

server_port = process.env.OPENSHIFT_NODEJS_PORT || 3000
server_ip_address = process.env.OPENSHIFT_NODEJS_IP || '127.0.0.1'

app = express()

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
  .use require('less-middleware')({ src: path.join(__dirname, 'public') })
  .use express.static(path.join(__dirname, 'public'))

if 'development' == app.get('env')
  app.use express.errorHandler()

app.get '/', routes.index

http.createServer(app).listen server_port, () ->
  console.log "Express server listening on port #{ app.get('port') }"
