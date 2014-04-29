config = require '../config'
xml2js = require 'xml2js'
querystring = require 'querystring'
url = require 'url'
rest = require 'rest'
types = require './types'
regions = require './regions'
schedule = require 'node-schedule'
util = require 'util'

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

pricingDate = null
groupsByName = null
pricedTypesById = null

load = () ->
  regionID = regions.find((x) -> x.regionName == config.regionName).regionID
  pricedGroups = for key, xs of types.groupBy 'groupName'
    do (key, xs) ->
      priceUrl = url.parse config.pricingURL
      priceUrl.search = querystring.stringify {typeid : y.typeID for y in xs, regionlimit : regionID}
      rest url.format priceUrl
      .then (res) ->
        parseString res.entity
      .then (res) ->
        category: xs[0].categoryName
        name: xs[0].groupName
        types: [xs, [res.evec_api.marketstat.type].flatten()].zip().map (x) -> {info: x[0], price: x[1].sell.avg * .85}
  groupsByName = Promise.all pricedGroups
  pricedTypesById = groupsByName
    .then (x) ->
      x
      .map (y) -> y.types
      .flatten()
      .indexBy (y) -> y.info.typeID
  pricingDate = new Date()

load()

schedule.scheduleJob '00 00 * * *', load

module.exports.pricingDate = -> pricingDate
module.exports.groupsByName = -> groupsByName
module.exports.pricedTypesById = -> pricedTypesById
