require 'es6-shim'

items = {}

module.exports.get = (key, ttl, work) ->
  new Promise (resolve, reject) ->
    if items[key]
      resolve items[key]
    else
      items[key] = Promise.resolve work()
      setTimeout ->
        delete items[key]
      , ttl
      resolve items[key]

module.exports.remove = (key) -> delete items[key]
