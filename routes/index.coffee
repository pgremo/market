exports.index = (req, res, groups) ->
  console.log 'index'
  res.render 'index', { groups: groups }