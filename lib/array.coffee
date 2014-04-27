_ = require 'lodash'

Array::flatten = () -> _.flatten this
Array::groupBy = (x) -> _.groupBy this, x
Array::indexBy = (x) -> _.indexBy this, x
Array::zip = () -> _.zip.apply this, this

