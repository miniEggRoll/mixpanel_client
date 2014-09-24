Q                   = require 'q'
querystring         = require 'querystring'
request             = require 'request'
_                   = require 'underscore'
moment              = require 'moment'

{mixpanelToken}     = require '../config'
host                = 'http://api.mixpanel.com'

serialize_base64 = (obj)->
    new Buffer(JSON.stringify obj).toString 'base64'

send_request = (type, data, callback)->
    qs = querystring.stringify {
        data: serialize_base64 data
        ip: 0
        img: 0
        verbose: 1
    }

    reqOpt = 
        url: "#{host}/#{type}/?#{qs}"
        method: 'GET'

    if _.isFunction callback then request reqOpt, callback
    else Q.Promise (resolve, reject, notify)->
            request reqOpt, (err, msg, body)->
                if err then reject err else resolve body

dateFormater = (date)->
    moment(date).format 'YYYY-MM-DD[T]HH:mm:ss'

class user_profile
    constructor: ({@$distinct_id, @$token})->
        @type = 'engage'
    send_request: send_request
    qs: ({$ip, $time, $ignore_time} = {})->
        {@$distinct_id, @$token, $ip, $time, $ignore_time}

    set: ({properties, options, callback})->
        throw new Error('invalid parameter') unless properties
        data = _.extend @qs(options), {$set: properties}
        @send_request @type, data, callback

    set_once: ({properties, options, callback})->
        throw new Error('invalid parameter') unless properties
        data = _.extend @qs(options), {$set_once: properties}
        @send_request @type, data, callback

    add: ({properties, options, callback})->
        throw new Error('invalid parameter') unless properties and _.every properties, _.isFinite
        data = _.extend @qs(options), {$add: properties}
        @send_request @type, data, callback

    append: ({properties, options, callback})->
        throw new Error('invalid parameter') unless properties
        data = _.extend @qs(options), {$append: properties}
        @send_request @type, data, callback

    union: ({properties, options, callback})->
        throw new Error('invalid parameter') unless properties and _.every properties, _.isArray
        data = _.extend @qs(options), {$union: properties}
        @send_request @type, data, callback

    unset: ({properties, options, callback})->
        throw new Error('invalid parameter') unless properties and _.isArray properties
        data = _.extend @qs(options), {$unset: properties}
        @send_request @type, data, callback

    delete: (callback)->
        data = _.extend @qs(), {$delete: ''}
        @send_request @type, data, callback

    track_charge: ({time, amount, options, callback})->
        properties = 
            $transactions:
                $time: dateFormater time
                $amount: amount
        @append {properties, options, callback}


class mixpanel
    constructor: ->
        @_token = mixpanelToken
    alias: (distinct_id, alias, callback)->
        eventName = '$create_alias'
        properties = {alias}
        @track {eventName, properties, distinct_id}, callback
    track: ({eventName, properties, distinct_id, timestamp, ip}, callback)->
        type = 'track'
        _.extend properties, {
            token: @_token
            distinct_id: distinct_id
            time: timestamp
            ip: ip
        }

        data = {
            event: eventName
            properties: properties
        }
        
        send_request type, data, callback
    profile: (distinct_id)-> 
        new user_profile {
            $distinct_id: distinct_id
            $token: @_token
        }

module.exports = -> new mixpanel()
