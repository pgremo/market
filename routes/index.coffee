exports.index = (req, res) ->
  res.render 'index', { groups: req.groups }