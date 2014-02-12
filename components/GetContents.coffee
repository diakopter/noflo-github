noflo = require 'noflo'
octo = require 'octo'

unless noflo.isBrowser()
  atob = require 'atob'

class GetContents extends noflo.AsyncComponent
  constructor: ->
    @token = null
    @repo = null

    @inPorts =
      repository: new noflo.Port
      path: new noflo.Port
      token: new noflo.Port
    @outPorts =
      out: new noflo.Port
      error: new noflo.Port

    @inPorts.repository.on 'data', (data) =>
      @repo = data

    @inPorts.token.on 'data', (data) =>
      @token = data

    super 'path'

  doAsync: (path, callback) ->
    api = octo.api()
    api.token @token if @token

    unless @repo
      callback new Error 'repository name required'
    repo = @repo

    request = api.get "/repos/#{repo}/contents/#{path}"
    request.on 'success', (res) =>
      unless res.body.content
        callback new Error 'content not found'
        return
      @outPorts.out.beginGroup repo
      @outPorts.out.beginGroup path
      @outPorts.out.send atob res.body.content
      @outPorts.out.endGroup()
      @outPorts.out.endGroup()
      @outPorts.out.disconnect()
      callback()
    request.on 'error', (err) =>
      @outPorts.out.disconnect()
      callback err.body
    @outPorts.out.connect()
    do request

exports.getComponent = -> new GetContents
