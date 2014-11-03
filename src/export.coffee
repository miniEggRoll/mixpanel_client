Q                       = require 'q'
request                 = require 'request'
_                       = require 'underscore'
moment                  = require 'moment'
debug                   = require('debug') 'mixpanel:export'
crypto                  = require 'crypto'
querystring             = require 'querystring'


host = 'http://mixpanel.com/api/2.0'
rawhost = 'https://data.mixpanel.com/api/2.0'
expire = Math.round(new Date().valueOf()/1000 + 100)

signature = (secret, params)->
    args_concat = _.chain params
    .keys()
    .sortBy (k)->k
    .map (k)-> "#{k}=#{params[k]}"
    .push secret
    .join ''
    .value()

    md5 = crypto.createHash 'md5'
    md5.update new Buffer(args_concat).toString('binary')
    md5.digest 'hex'

qs = (params = {})->
    params.sig = signature @secret, _.extend(params, {@api_key, expire})
    querystring.stringify params

req = (reqOpt)->
    Q.Promise (resolve, reject, notify)->
        request reqOpt, (err, msg, body)->
            if err then reject err else resolve JSON.parse body

generateParam = ({required, optional})->
    param = _.chain optional
    .pick (o)-> !_.isUndefined o
    .extend required
    .value()

class events
    constructor: ({@secret, @api_key})->
    events: ({event, type, unit, interval})->
        format = 'json'
        throw {message: 'event must be string array'} unless _.isArray event
        try
            event = JSON.stringify event
        catch e
            throw {message: 'event contains invalid element'}

        required = {event, type, unit, interval}
        optional = {format}
        params = generateParam {required, optional}
        url = "#{host}/events/?" + qs.call @, params
        req {url}
    top: ({type, limit})->
        required = {type}
        optional = {limit}
        params = generateParam {required, optional}
        url = "#{host}/events/top?" + qs.call @, params
        req {url}
    names: ({type, limit})->
        required = {type}
        optional = {limit}
        params = generateParam {required, optional}
        url = "#{host}/events/names?" + qs.call @, params
        req {url}

class eventProp
    constructor: ({@secret, @api_key})->
    properties: ({event, name, values, type, unit, interval, limit})->
        throw {message: 'values must be string array'} unless _.isArray(values) or _.isUndefined(values)
        format = 'json'
        try
            values = JSON.stringify values
        catch e
            throw {message: 'values contain invalid element'}
        
        required = {event, type, name, unit, interval}
        optional = {limit, values, format}
        params = generateParam {required, optional}
        url = "#{host}/events/properties?" + qs.call @, params
        req {url}
    top: ({event, limit})->
        required = {event}
        optional = {limit}
        params = generateParam {required, optional}
        url = "#{host}/events/properties/top?" + qs.call @, params
        req {url}
    values: ({event, name, limit, bucket})->
        required = {event, name}
        optional = {limit, bucket}
        params = generateParam {required, optional}
        url = "#{host}/events/properties/values?" + qs.call @, params
        req {url}

class funnels
    constructor: ({@secret, @api_key})->
    funnel: ({funnel_id, from_date, to_date, length, interval, unit, _on, where, limit})->
        from_date = moment(from_date).format 'YYYY-MM-DD'
        to_date = moment(to_date).format 'YYYY-MM-DD'
        required = {funnel_id}
        optional = {from_date, to_date, length, interval, unit, _on, where, limit}
        params = generateParam {required, optional}
        url = "#{host}/funnels?" + qs.call @, params
        req {url}
    list: ->
        url = "#{host}/funnels/list?" + qs.call @
        req {url}
    getByName: (options)->
        {name} = options
        @list().then (list)=>
            {funnel_id} = _.findWhere list, {name}
            options.funnel_id = funnel_id
            @funnel options

class annotations
    constructor: ({@secret, @api_key})->
    list: ({from_date, to_date})->
        params = 
            from_date: moment(from_date).format 'YYYY-MM-DD'
            to_date: moment(to_date).format 'YYYY-MM-DD'
        url = "#{host}/annotations/?" + qs.call @, params
        req {url}
    create: ({date, description})->
        params = 
            date: moment(date).format 'YYYY-MM-DD HH:mm:ss'
            description: description
        url = "#{host}/annotations/create?" + qs.call @, params
        req {url}
    update: ({id, date, description})->
        params =
            id: id
            date: moment(date).format 'YYYY-MM-DD HH:mm:ss'
            description: description
        url = "#{host}/annotations/update?" + qs.call @, params
        req {url}
    delete: (id)->
        params = {id}
        url = "#{host}/annotations/delete?" + qs.call @, params
        req {url}

class segmentation
    constructor: ({@secret, @api_key})->
    segmentation: ({event, from_date, to_date, unit, limit, type, expression})->
        required = 
            event: event
            from_date: moment(from_date).format 'YYYY-MM-DD'
            to_date: moment(to_date).format 'YYYY-MM-DD'

        optional =
            unit: unit
            limit: limit
            type: type
        params = generateParam {required, optional}
        _.extend params, expression
        url = "#{host}/segmentation?" + qs.call @, params
        req {url}
    numeric: ({event, from_date, to_date, unit, type, expression})->
        required = 
            event: event
            from_date: moment(from_date).format 'YYYY-MM-DD'
            to_date: moment(to_date).format 'YYYY-MM-DD'
        optional =
            unit: unit
            type: type
        params = generateParam {required, optional}
        _.extend params, expression
        url = "#{host}/segmentation/numeric?" + qs.call @, params
        req {url}
    sum: ({event, from_date, to_date, unit, expression})->
        required = 
            event: event
            from_date: moment(from_date).format 'YYYY-MM-DD'
            to_date: moment(to_date).format 'YYYY-MM-DD'
        optional =
            unit: unit
        params = generateParam {required, optional}
        _.extend params, expression
        url = "#{host}/segmentation/sum?" + qs.call @, params
        req {url}
    average: ({event, from_date, to_date, unit, expression})->
        required = 
            event: event
            from_date: moment(from_date).format 'YYYY-MM-DD'
            to_date: moment(to_date).format 'YYYY-MM-DD'
        optional =
            unit:unit
        params = generateParam {required, optional}
        _.extend params, expression
        url = "#{host}/segmentation/average?" + qs.call @, params
        req {url}

class mp
    constructor: (config)->
        {@secret, @api_key} = config
        @events = new events config
        @eventProp = new eventProp config
        @funnels = new funnels config
        @annotations = new annotations config
        @segmentation = new segmentation config
    raw: ({from_date, to_date, event, expression, bucket}, cb)=>
        from_date = moment(from_date).format 'YYYY-MM-DD'
        to_date = moment(to_date).format 'YYYY-MM-DD'
        required = {from_date, to_date}
        optional = {event, bucket}
        params = generateParam {required, optional}
        _.extend params, expression
        url = "#{rawhost}/export?" + qs.call @, params
        if cb and _.isFunction cb
            request {url}, cb
        else request {url}
    retention: ({from_date, to_date, retention_type, born_event, event, interval, interval_count, unit, limit, expression})=>
        required = 
            from_date: moment(from_date).format 'YYYY-MM-DD'
            to_date: moment(to_date).format 'YYYY-MM-DD'
        optional = {
            retention_type
            born_event
            event
            interval
            interval_count
            unit
            limit
        }
        params = generateParam {required, optional}
        _.extend params, expression    
        url = "#{host}/retention?" + qs.call @, params
        req {url}
    engage: ({where, session_id, page, distinct_id})=>
        required = {}
        optional = {distinct_id, where, session_id, page}
        params = generateParam {required, optional}
        url = "#{host}/engage/?" + qs.call @, params
        req {url}


module.exports = (config)-> new mp config
