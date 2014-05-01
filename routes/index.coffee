pricing = require '../data/pricing'
parser = require '../lib/eve2json'

exports.index = (req, res) ->
  pricing.groupsByName()
    .then (x) ->
      res.render 'index', groups: x
    .catch (err) -> console.log err

exports.price = (req, res) ->
  pricing.pricedTypesById()
  .then (ipts) ->
    priced = for typeid, num of req.body when num != ''
      [type, count] = [ipts[typeid], parseFloat num]
      {type: type, count: count, total: count * type.price}
    res.render 'index_post',
      count: (priced
        .map (x) -> x.count
        .reduce (seed, x) -> seed + x)
      total: (priced
        .map (x) -> x.total
        .reduce (seed, x) -> seed + x)
      types: priced
  .catch (err) -> console.log err

exports.index2 = (req, res) ->
  res.render 'index2'

exports.price2 = (req, res) ->
  pricing.pricedTypesByName().then (items) ->
    [result, bad_lines] = parser.parse req.body.data
    priced = for x in result when items[x.name]
      {price: items[x.name].price, total: items[x.name].price * x.quantity, item: x}
    res.render 'index_post2',
      count: (priced
        .map (x) -> x.item.quantity
        .reduce (seed, x) -> seed + x)
      total: (priced
        .map (x) -> x.total
        .reduce (seed, x) -> seed + x)
      types: priced
  .catch (err) -> console.log err
