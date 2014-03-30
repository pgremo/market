exports.index = (req, res) ->
  console.log req.groups
  res.render 'index', { groups: req.groups }