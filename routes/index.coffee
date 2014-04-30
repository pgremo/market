pricing = require '../data/pricing'

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