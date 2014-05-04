pricing = require '../data/pricing'
parser = require 'eve2json'

exports.index = (req, res) ->
  res.render 'index'

exports.price = (req, res) ->
  pricing.pricedTypesByName().then (items) ->
    [result, bad_lines] = parser.parse req.body.data
    priced = for x in result when items[x.name]
      {price: items[x.name].price, total: items[x.name].price * x.quantity, item: x}
    res.render 'index_post',
      count: (priced
        .map (x) -> x.item.quantity
        .reduce (seed, x) -> seed + x)
      total: (priced
        .map (x) -> x.total
        .reduce (seed, x) -> seed + x)
      types: priced
  .catch (err) -> console.log err
