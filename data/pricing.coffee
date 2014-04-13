config = require('config')
xml2js = require 'xml2js'
querystring = require 'querystring'
url = require 'url'
rest = require 'rest'
types = require './types'
regions = require './regions'

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

groups = for key, xs of types.groupBy 'groupName'
  do (xs) ->
    priceUrl = url.parse config.pricingURL
    priceUrl.search = querystring.stringify {typeid : y.typeID for y in xs, regionlimit : regionID}
    rest url.format priceUrl
    .then (res) ->
      parseString res.entity
    .then (res) ->
      category: xs[0].categoryName
      name: xs[0].groupName
      types: [xs, res.evec_api.marketstat.type].zip().map (x) -> {info: x[0], marketstat: x[1]}

groupsByName = Promise.all groups

module.exports.groupsByName = groupsByName

pricedTypesById = groupsByName
.then (x) ->
  x
  .map (y) -> y.types
  .flatten()
  .indexBy (y) -> y.info.typeID

module.exports.pricedTypesById = pricedTypesById
