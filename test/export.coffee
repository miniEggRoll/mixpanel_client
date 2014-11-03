Q                           = require 'q'
{assert}                    = require 'chai'
track                       = require '../src/track'
_export                     = require '../src/export'
debug                       = require('debug') 'test'
moment                      = require 'moment'
_                           = require 'underscore'
config                      = require '../config'

{annotations, events, eventProp, funnels, segmentation, retention, engage, raw} = _export config

describe 'export', ->
    timestamp = eventName = distinct_id = today = null
    beforeEach ->
        timestamp = new Date().valueOf()
        eventName = "test_#{timestamp}"
        today = moment().format 'YYYY-MM-DD'
        distinct_id = "profile_#{timestamp}"

    describe 'raw', ->
        opt =
            from_date: moment().subtract(1, 'day').toDate()
            to_date: new Date()
        @timeout 20000
        it 'return raw data stream', (done)->
            body = ''
            raw opt
            .on 'data', (chunk)->
                body += chunk.toString()
            .on 'complete', ->
                result = _.chain body.split('\n')
                .compact()
                .map JSON.parse
                .value()

                _.each result, ({event, properties})->
                    assert.isString event
                    assert.isObject properties
                do done
        it 'export raw event', (done)->
            raw opt, (err, msg, body)->
                result = _.chain body.split('\n')
                .compact()
                .map JSON.parse
                .value()

                _.each result, ({event, properties})->
                    assert.isString event
                    assert.isObject properties
                do done

    describe 'annotations', ->
        it 'create annotations', ->
            id = null
            createDate = new Date()
            updateDesc = "update_#{timestamp}"
            annotations.create {
                date: createDate
                description: timestamp
            }
            .then (result)->
                assert.isObject result
                assert.property result, 'error'
        it 'list annotations', ->
            annotations.list {
                from_date: moment().subtract(1, 'hour').toDate()
                to_date: moment().add(1, 'hour').toDate()
            }
            .then ({annotations, error})->
                anno = annotations
                assert.isArray anno
                assert.notOk error
        it 'update annotations', ->
            annotations.update {
                id: 1
                date: new Date()
                description: 'test'
            }
            .then (result)->
                assert.isObject result
                assert.property result, 'error'
        it 'delete annotations', ->
            annotations.delete {
                id: 1
            }
            .then (result)->
                assert.isObject result
                assert.property result, 'error'

    describe 'events', ->
        it 'return events', ->
            events.events {
                event: ['test']
                type: 'general'
                unit: 'day'
                interval: '2'
            }
            .then ({data, legend_size})->
                assert.isObject data
                assert.property data, 'series'
                assert.property data, 'values'
                assert.isNumber legend_size
        it 'return top events today', ->
            events.top {
                type: 'general'
                limit: 2
            }
            .then ({events, type})->
                assert.isArray events
                assert.isString type
        it 'return top events over the past 31 days', ->
            events.names {
                type: 'general'
                limit: 5
            }
            .then (result)->
                assert.isArray result

    describe 'event properties', ->
        it 'return event property', ->
            eventProp.properties {
                event: 'testevent'
                name: 'testproperty'
                type: 'general'
                unit: 'day'
                interval: 2
                limit: 2
            }
            .then ({data, legend_size})->
                assert.isObject data
                assert.property data, 'series'
                assert.property data, 'values'
                assert.isNumber legend_size
        it 'return top property names for an event', ->
            eventProp.top {
                event: 'test'
                top: 5
            }
            .then (result)->
                assert.isObject result
                _.every result, (r)-> assert.property r, 'count'
        it 'return top value for a property', ->
            eventProp.values {
                event: 'test'
                name: 'testProp'
                limit: 3
                bucket: 'testla'
            }
            .then (result)->
                assert.isArray result
    
    describe 'funnels', ->
        it 'list funnels', ->
            funnels.list()
            .then (result)->
                assert.isArray result
                _.each result, assert.isObject
        it 'return data from a funnel', ->
            funnels.list()
            .then ([{funnel_id, name}])->
                funnels.funnel {
                    funnel_id: funnel_id
                    from_date: new Date()
                    to_date: new Date()
                    length: 1
                    unit: 'day'
                }
                .then (result)->
                    {data, meta: {dates}} = result
                    _.each data, assert.isObject
                    assert.isArray dates
        it 'return data from a funnel by funnel name', ->
            funnels.list()
            .then ([{funnel_id, name}])->
                funnels.getByName {
                    name: name
                    from_date: new Date()
                    to_date: new Date()
                    length: 1
                    unit: 'day'
                }
            .then (result)->
                {data, meta: {dates}} = result
                _.each data, assert.isObject
                assert.isArray dates



    describe 'segmentation', ->
        it 'return segmented data of single event', ->
            segmentation.segmentation {
                event: 'test'
                from_date: new Date()
                to_date: new Date()
            }
            .then ({data: {series, values}, legend_size})->
                assert.isArray series
                assert.isObject values
                assert.isNumber legend_size
        it 'can cast string to number when segmenting', ->
            track().track {
                eventName: 'test'
                properties:
                    val: 1
            }
            .then ->
                segmentation.numeric {
                    event: 'test'
                    from_date: new Date()
                    to_date: new Date()
                    expression: 
                        on: 'number(properties["val"])'
                }
            .then ({data: {series, values}, legend_size})->
                assert.isArray series
                assert.isObject values
                assert.isNumber legend_size
        it 'sums an expression for event per unit time', ->
            track().track {
                eventName: 'test'
                properties:
                    val: 1
            }
            .then ->
                segmentation.sum {
                    event: 'test'
                    from_date: new Date()
                    to_date: new Date()
                    expression: 
                        on: 'number(properties["val"])'
                }
            .then ({results, status})->
                assert.isString status
                assert.isObject results
        it 'averages an expression for events per unit time', ->
            track().track {
                eventName: 'test'
                properties:
                    val: 1
            }
            .then ->
                segmentation.average {
                    event: 'test'
                    from_date: new Date()
                    to_date: new Date()
                    expression: 
                        on: 'number(properties["val"])'
                }
            .then ({results, status})->
                assert.isString status
                assert.isObject results
    describe 'retention', ->
        it 'return cohort analysis', ->
            retention {
                from_date: new Date()
                to_date: new Date()
                retention_type: 'compounded'
            }
            .then (result)->
                _.each result, (r)-> assert.property r, 'counts'
    describe 'engage', ->
        it 'query people data', ->
            engage {distinct_id: '123'}
            .then ({page, page_size, results, session_id, status, total})->
                assert.isNumber page
                assert.isNumber page_size
                assert.isArray results
                assert.isString session_id
                assert.isString status
                assert.isNumber total
