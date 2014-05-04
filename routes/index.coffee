pricing = require '../data/pricing'
parser = require 'eve2json'

exports.index = (req, res) ->
  res.render 'index'

exports.price = (req, res) ->
  pricing.pricedTypesByName()
  .then (items) ->
    [result, bad_lines] = parser.parse req.body.data
    priced = for x in result when items[x.name]
      item = items[x.name]
      {name: x.name, quantity: x.quantity, price: item.price, totalVolume: item.info.volume * x.quantity, totalPrice: item.price * x.quantity, item: item.info}
    res.render 'index_post',
      count: (priced
        .map (x) -> x.quantity
        .reduce (seed, x) -> seed + x)
      totalVolume: (priced
        .map (x) -> x.totalVolume
        .reduce (seed, x) -> seed + x)
      totalPrice: (priced
        .map (x) -> x.totalPrice
        .reduce (seed, x) -> seed + x)
      types: priced
  .catch (err) -> console.log err
