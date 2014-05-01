numeral = require 'numeral'
l = require 'lodash'

splitAndStrip = (s) ->
  lines = for line in s.trim().replace(/\r\n|\n\r|\n|\r/g,'\n').split(/\n/)
    line.trim().replace('\xa0', '').replace('\xc2', '')
  line for line in lines when line?

matchLines = (regex, lines) ->
  matches = []
  bad_lines = []
  for line in lines
    regex.lastIndex = 0
    match = line.match regex
    if match?
      matches.push match[1..]
    else
      bad_lines.push line
  [matches, bad_lines]

ASSET_LIST = ///
   ^([\S\x20]*)                         # name
  \t([\d,\.]*)                          # quantity
  (\t([\S\x20]*))?                      # group
  (\t([\S\x20]*))?                      # category
  (\t(XLarge|Large|Medium|Small|))?     # size
  (\t(High|Medium|Low|Rigs|[\d\x20]*))? # slot
  (\t([\d\x20,\.]*)\x20m3)?             # volume
  (\t([\d]+|))?                         # meta level
  (\t([\d]+|))?$                        # tech level
///

module.exports.asset = (lines) ->
  [matches, bad_lines] = matchLines ASSET_LIST, lines
  result = for [name, quantity, _, group, _, category, _, size, _, slot, _, volume, _, meta_level, _, tech_level] in matches
    {
      name: name,
      quantity: numeral().unformat(quantity) or 1,
      group: group,
      category: category,
      size: size,
      slot: slot,
      volume: numeral().unformat(volume) or 0,
      meta_level: meta_level,
      tech_level: tech_level
    }
  [result, bad_lines]

# 10 x Cargo Scanner II | 10x Cargo Scanner II | 10 Cargo Scanner II
LISTING_RE = /^([\d,\.]+?)\x20?x?\x20([\S\x20]+)$/
# Cargo Scanner II x10 | Cargo Scanner II x 10 | Cargo Scanner II 10
LISTING_RE2 = /^([\S\x20]+?)\x20x?\x20?([\d,\.]+)$/
# Cargo Scanner II
LISTING_RE3 = /^([\S\x20]+)$/

module.exports.list = (lines) ->
  [matches, bad_lines] = matchLines LISTING_RE, lines
  [matches2, bad_lines2] = matchLines LISTING_RE2, bad_lines
  [matches3, bad_lines3] = matchLines LISTING_RE3, bad_lines2
  result = []
  for [quantity, name] in matches
    result.push name: name.trim(), quantity: numeral().unformat(quantity) or 1
  for [name, quantity] in matches2
    result.push name: name.trim(), quantity: numeral().unformat(quantity) or 1
  for [name] in matches3
    result.push name: name.trim(), quantity: 1
  [result, bad_lines3]

module.exports.parse = (raw) ->
  lines = splitAndStrip(raw)
  parsers = [module.exports.asset, module.exports.list]
  result = while (parser = parsers.shift()) and lines
    [good, lines] = parser(lines)
    good
  [l.flatten(result), lines]
