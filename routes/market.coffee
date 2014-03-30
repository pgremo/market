exports.contractDetail = (req, res, result) ->
  console.log 'index_post'
  res.render 'index_post', { result: result }