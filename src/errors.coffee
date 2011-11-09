module.exports =
  # 400
  BadRequestError: ->
    message: 'Bad Request',
    name: 'badRequestError'
  
  # 401
  AuthenticationRequiredError: ->
    message: 'Authentication Required Error',
    name: 'authenticationRequiredError'

  # 403
  AuthorizationError: ->
    message: 'Authorization Error',
    name: 'authorizationError'

  # 404
  NotFoundError: ->
    message: 'Not Found',
    name: 'notFoundError'

  # 406
  NotAcceptable: ->
    message: 'Not Acceptable',
    name: 'notAcceptableError'

  # 500
  InternalServerError: ->
    message: 'Internal Server Error',
    name: 'internalServerError'

  # 503
  DownForMaintenanceError: ->
    message: 'Down for Maintenance',
    name: 'downForMaintenanceError'

  # Everything else
  UnexpectedError: (message) ->
    message: message,
    name: 'unexpectedError'
