Q                           = require 'q'
{assert}                    = require 'chai'
mixpanel                    = require '../src/track'
_export                      = require '../src/export'
debug                       = require('debug') 'test'
moment                      = require 'moment'

{events, eventProperty, engage} = _export

describe 'track', ->
    timestamp = eventName = distinct_id = today = null
    beforeEach ->
        timestamp = new Date().valueOf()
        eventName = "test_#{timestamp}"
        today = moment().format 'YYYY-MM-DD'
        distinct_id = "profile_#{timestamp}"

    it 'send track event', ->
        new mixpanel().track {
            eventName: eventName
            distinct_id: distinct_id
            timestamp: Math.round(timestamp/1000)
            properties: 
                _timestamp: timestamp
        }
        .delay 5000
        .then ->
            exist = events {
                eventNames: [eventName]
                type: 'general'
                unit: 'day'
                interval: 2
            }
            property = eventProperty {
                event: eventName
                name: '_timestamp'
                type: 'general'
                values: [timestamp]
                interval: 2
                unit: 'day'
            }
            Q.all [exist, property]
        .then ([exist, property])->
            assert.deepPropertyVal exist, "data.values.#{eventName}.#{today}", 1
            assert.deepPropertyVal property, "data.values.#{timestamp}.#{today}", 1
    
    it 'create profile with properties', ->
        fName = 'aaron'
        lName = "cheng_#{timestamp}"
        user = new mixpanel().profile distinct_id

        user.set {
            properties:
                $first_name: fName
                $last_name: lName
        }
        .delay 1000
        .then ->
            engage {
                distinct_id: distinct_id
            }
        .then (profile)->
            result = profile.results[0]
            assert.propertyVal result, "$distinct_id", distinct_id
            assert.deepPropertyVal result, "$properties.$first_name", fName
            assert.deepPropertyVal result, "$properties.$last_name", lName
    
    it 'only set empty property with set_once', ->
        fName = 'aaron'
        lName = "cheng_#{timestamp}"
        user = new mixpanel().profile distinct_id

        user.set {
            properties:
                $first_name: fName
                $last_name: lName
        }
        .delay 1000
        .then ->
            engage {
                distinct_id: distinct_id
            }
        .then (profile)->
            assert.deepPropertyVal profile, "results.0.$distinct_id", distinct_id
        .then ->
            user.set_once {
                properties:
                    $first_name: 'bbron'
                    test: 'test'
            }
        .delay 1000
        .then ->
            engage {
                distinct_id: distinct_id
            }
        .then (profile)->
            assert.deepPropertyVal profile, "results.0.$distinct_id", distinct_id
            assert.deepPropertyVal profile, "results.0.$properties.$first_name", fName
            assert.deepPropertyVal profile, "results.0.$properties.test", 'test'


    it 'add properties by increments', ->
        user = new mixpanel().profile distinct_id

        user.set {
            properties:
                count: 1
        }
        .delay 1000
        .then ->
            engage {distinct_id}
        .then (profile)->
            assert.deepPropertyVal profile, "results.0.$distinct_id", distinct_id
            assert.deepPropertyVal profile, "results.0.$properties.count", 1
        .then ->
            user.add {
                properties: 
                    count: 3
            }
        .delay 1000
        .then ->
            engage {distinct_id}
        .then (profile)->
            assert.deepPropertyVal profile, "results.0.$distinct_id", distinct_id
            assert.deepPropertyVal profile, "results.0.$properties.count", 4

    it 'append to specific properties', ->
        user = new mixpanel().profile distinct_id

        user.set {
            properties:
                color: ['red']
        }
        .delay 1000
        .then -> engage {distinct_id}
        .then (profile)->
            assert.deepPropertyVal profile, "results.0.$distinct_id", distinct_id
            assert.sameMembers profile.results[0].$properties.color, ['red']
        .then ->
            user.append {
                properties:
                    color: 'blue'
            }
        .delay 2000
        .then ->
            engage {distinct_id}
        .then (profile)->
            assert.sameMembers profile.results[0].$properties.color, ['red', 'blue']

    it 'append properties without duplicate entries by union', ->
        user = new mixpanel().profile distinct_id
        user.set {
            properties:
                color: ['red']
        }
        .delay 1000
        .then -> engage {distinct_id}
        .then (profile)->
            assert.deepPropertyVal profile, "results.0.$distinct_id", distinct_id
            assert.sameMembers profile.results[0].$properties.color, ['red']
        .then ->
            user.union {
                properties:
                    color: ['blue', 'red']
            }
        .delay 2000
        .then ->
            engage {distinct_id}
        .then (profile)->
            assert.sameMembers profile.results[0].$properties.color, ['red', 'blue']
    it 'unset profile', ->
        fName = 'aaron'
        lName = "cheng_#{timestamp}"
        user = new mixpanel().profile distinct_id

        user.set {
            properties:
                $first_name: fName
                $last_name: lName
        }
        .delay 1000
        .then ->
            engage {
                distinct_id: distinct_id
            }
        .then (profile)->
            result = profile.results[0]
            assert.propertyVal result, "$distinct_id", distinct_id
            assert.deepPropertyVal result, "$properties.$first_name", fName
            assert.deepPropertyVal result, "$properties.$last_name", lName
        .then ->
            user.unset {
                properties: ['$first_name']
            }
        .delay 1000
        .then -> engage {distinct_id}
        .then (profile)->
            result = profile.results[0]
            assert.notDeepProperty result, "$properties.$first_name"
            assert.deepPropertyVal result, "$properties.$last_name", lName
    it 'delete profile', ->
        fName = 'aaron'
        lName = "cheng_#{timestamp}"
        user = new mixpanel().profile distinct_id

        user.set {
            properties:
                $first_name: fName
                $last_name: lName
        }
        .delay 1000
        .then -> engage {distinct_id}
        .then (profile)->
            result = profile.results[0]
            assert.propertyVal result, "$distinct_id", distinct_id
            assert.deepPropertyVal result, "$properties.$first_name", fName
            assert.deepPropertyVal result, "$properties.$last_name", lName
        .then -> do user.delete
        .delay 1000
        .then -> engage {distinct_id}
        .then (profile)->
            assert.lengthOf profile.results, 0
    it 'track user charge', ->
        fName = 'aaron'
        lName = "cheng_#{timestamp}"
        user = new mixpanel().profile distinct_id

        user.set {
            properties:
                $first_name: fName
                $last_name: lName
        }
        .delay 1000
        .then -> engage {distinct_id}
        .then (profile)->
            result = profile.results[0]
            assert.propertyVal result, "$distinct_id", distinct_id
        .then -> user.track_charge {
            time: new Date(timestamp)
            amount: 100
        }
        .delay 1000
        .then -> engage {distinct_id}
        .then (profile)->
            assert.lengthOf profile.results[0].$properties.$transactions, 1
    it 'create alias to user'
        # fName = 'aaron'
        # lName = "cheng_#{timestamp}"
        # alias = "test#{distinct_id}"
        # mp = new mixpanel()
        # user = mp.profile distinct_id

        # user.set {
        #     properties:
        #         $first_name: fName
        #         $last_name: lName
        # }
        # .delay 1000
        # .then -> engage {distinct_id}
        # .then (profile)->
        #     result = profile.results[0]
        #     assert.propertyVal result, "$distinct_id", distinct_id
        # .then -> mp.alias distinct_id, alias
        # .delay 15000
        # .then -> engage {distinct_id: alias}
        # .then (profile)->
        #     debug profile
