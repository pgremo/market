require 'es6-shim'
config = require '../config'
xml2js = require 'xml2js'
querystring = require 'querystring'
url = require 'url'
rest = require 'rest'
types = require './types'
regions = require './regions'
cache = require '../lib/cache'
_ = require 'lodash'

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

regionID = regions.find((x) -> x.regionName == config.regionName).regionID

expiry = ->
  now = new Date()
  new Date(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() + 1).getTime() - now.getTime()

groupsByName = ->
  cache.get 'groupsByName', expiry(), ->
    pricedGroups = for key, xs of _.groupBy types, 'groupName'
      do (key, xs) ->
        priceUrl = url.parse config.pricingURL
        priceUrl.search = querystring.stringify {typeid : y.typeID for y in xs, regionlimit : regionID}
        rest url.format priceUrl
        .then (res) ->
          parseString res.entity
        .then (res) ->
          category: xs[0].categoryName
          name: xs[0].groupName
          types: _.zip(xs, _.flatten([res.evec_api.marketstat.type])).map (x) -> {info: x[0], price: x[1].sell.avg * .85}
    Promise.all pricedGroups

pricedTypesByName = ->
  cache.get 'pricedTypesByName', expiry(), ->
    groupsByName()
      .then (x) ->
        _.chain(x)
        .map (y) -> y.types
        .flatten()
        .indexBy (y) -> y.info.typeName
        .valueOf()

module.exports.pricingDate = -> new Date()
module.exports.groupsByName = groupsByName
module.exports.pricedTypesByName = pricedTypesByName