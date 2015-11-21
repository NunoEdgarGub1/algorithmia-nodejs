https = require('https')
http = require('http')
url = require('url')

Algorithm = require('./algorithm.js')
Data = require('./data.js')

defaultApiAddress = 'https://api.algorithmia.com/v1/'

class AlgorithmiaClient
  constructor: (key, address) ->
    @apiAddress = address || process.env.ALGORITHMIA_API || defaultApiAddress

    key = key || process.env.ALGORITHMIA_API_KEY
    if key
      if key.indexOf('Simple ') == 0
        @apiKey = key
      else
        @apiKey = 'Simple ' + key
    else
      @apiKey = ''

  # algo
  algo: (path) ->
    new Algorithm(this, path)

  # file
  file: (path) ->
    new Data(this, path)

  # internal http-helper
  req: (path, method, data, cheaders, callback) ->

    # default header
    dheader =
      'Content-Type': 'application/JSON'
      'Accept': 'application/JSON'
      'Authorization': @apiKey
      'User-Agent': 'NodeJS/' + process.version

    # merge default header with custom header
    for key,val of cheaders
      dheader[key] = val

    # make options
    options = url.parse(@apiAddress + path)
    options.method = method
    options.headers = dheader

    # helper method to switch between http / https
    protocol = if options.protocol == "https:" then https else http

    # trigger call
    httpRequest = protocol.request(options, (res) ->
      res.setEncoding 'utf8'
      chunks = []

      res.on 'data', (chunk) ->
        chunks.push chunk

      res.on 'end', ->
        buff = chunks.join('')

        if (dheader['Accept'] == 'application/JSON')
          body = JSON.parse(buff)
        else
          body = buff

        if callback
          if res.statusCode < 200 || res.statusCode >= 300
            if !body
              body = {}
            if !body.error
              body.error = message: 'HTTP Response: ' + res.statusCode
          callback body, res.statusCode
        return
      res
    )

    httpRequest.write data
    httpRequest.end()
    return

algorithmia = {

  client: (key, address) ->
    new AlgorithmiaClient(key, address)

  # Convinience methods to use default client
  algo: (path) ->
    @defaultClient = @defaultClient || new AlgorithmiaClient()
    @defaultClient.algo(path)

  file: (path) ->
    @defaultClient = @defaultClient || new AlgorithmiaClient()
    @defaultClient.algo(path)
}

module.exports = exports = algorithmia
