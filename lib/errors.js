
  module.exports = {
    BadRequestError: function() {
      return {
        message: 'Bad Request',
        name: 'badRequestError'
      };
    },
    AuthenticationRequiredError: function() {
      return {
        message: 'Authentication Required Error',
        name: 'authenticationRequiredError'
      };
    },
    AuthorizationError: function() {
      return {
        message: 'Authorization Error',
        name: 'authorizationError'
      };
    },
    NotFoundError: function() {
      return {
        message: 'Not Found',
        name: 'notFoundError'
      };
    },
    NotAcceptable: function() {
      return {
        message: 'Not Acceptable',
        name: 'notAcceptableError'
      };
    },
    InternalServerError: function() {
      return {
        message: 'Internal Server Error',
        name: 'internalServerError'
      };
    },
    DownForMaintenanceError: function() {
      return {
        message: 'Down for Maintenance',
        name: 'downForMaintenanceError'
      };
    },
    UnexpectedError: function(message) {
      return {
        message: message,
        name: 'unexpectedError'
      };
    }
  };
