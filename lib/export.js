(function() {
  var Q, annotations, crypto, debug, eventProp, events, expire, funnels, generateParam, host, moment, mp, qs, querystring, rawhost, req, request, segmentation, signature, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Q = require('q');

  request = require('request');

  _ = require('underscore');

  moment = require('moment');

  debug = require('debug')('mixpanel:export');

  crypto = require('crypto');

  querystring = require('querystring');

  host = 'http://mixpanel.com/api/2.0';

  rawhost = 'https://data.mixpanel.com/api/2.0';

  expire = Math.round(new Date().valueOf() / 1000 + 100);

  signature = function(secret, params) {
    var args_concat, md5;
    args_concat = _.chain(params).keys().sortBy(function(k) {
      return k;
    }).map(function(k) {
      return "" + k + "=" + params[k];
    }).push(secret).join('').value();
    md5 = crypto.createHash('md5');
    md5.update(new Buffer(args_concat).toString('binary'));
    return md5.digest('hex');
  };

  qs = function(params) {
    if (params == null) {
      params = {};
    }
    params.sig = signature(this.secret, _.extend(params, {
      api_key: this.api_key,
      expire: expire
    }));
    return querystring.stringify(params);
  };

  req = function(reqOpt) {
    return Q.Promise(function(resolve, reject, notify) {
      return request(reqOpt, function(err, msg, body) {
        if (err) {
          return reject(err);
        } else {
          return resolve(JSON.parse(body));
        }
      });
    });
  };

  generateParam = function(_arg) {
    var optional, param, required;
    required = _arg.required, optional = _arg.optional;
    return param = _.chain(optional).pick(function(o) {
      return !_.isUndefined(o);
    }).extend(required).value();
  };

  events = (function() {
    function events(_arg) {
      this.secret = _arg.secret, this.api_key = _arg.api_key;
    }

    events.prototype.events = function(_arg) {
      var e, event, format, interval, optional, params, required, type, unit, url;
      event = _arg.event, type = _arg.type, unit = _arg.unit, interval = _arg.interval;
      format = 'json';
      if (!_.isArray(event)) {
        throw {
          message: 'event must be string array'
        };
      }
      try {
        event = JSON.stringify(event);
      } catch (_error) {
        e = _error;
        throw {
          message: 'event contains invalid element'
        };
      }
      required = {
        event: event,
        type: type,
        unit: unit,
        interval: interval
      };
      optional = {
        format: format
      };
      params = generateParam({
        required: required,
        optional: optional
      });
      url = ("" + host + "/events/?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    events.prototype.top = function(_arg) {
      var limit, optional, params, required, type, url;
      type = _arg.type, limit = _arg.limit;
      required = {
        type: type
      };
      optional = {
        limit: limit
      };
      params = generateParam({
        required: required,
        optional: optional
      });
      url = ("" + host + "/events/top?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    events.prototype.names = function(_arg) {
      var limit, optional, params, required, type, url;
      type = _arg.type, limit = _arg.limit;
      required = {
        type: type
      };
      optional = {
        limit: limit
      };
      params = generateParam({
        required: required,
        optional: optional
      });
      url = ("" + host + "/events/names?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    return events;

  })();

  eventProp = (function() {
    function eventProp(_arg) {
      this.secret = _arg.secret, this.api_key = _arg.api_key;
    }

    eventProp.prototype.properties = function(_arg) {
      var e, event, format, interval, limit, name, optional, params, required, type, unit, url, values;
      event = _arg.event, name = _arg.name, values = _arg.values, type = _arg.type, unit = _arg.unit, interval = _arg.interval, limit = _arg.limit;
      if (!(_.isArray(values) || _.isUndefined(values))) {
        throw {
          message: 'values must be string array'
        };
      }
      format = 'json';
      try {
        values = JSON.stringify(values);
      } catch (_error) {
        e = _error;
        throw {
          message: 'values contain invalid element'
        };
      }
      required = {
        event: event,
        type: type,
        name: name,
        unit: unit,
        interval: interval
      };
      optional = {
        limit: limit,
        values: values,
        format: format
      };
      params = generateParam({
        required: required,
        optional: optional
      });
      url = ("" + host + "/events/properties?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    eventProp.prototype.top = function(_arg) {
      var event, limit, optional, params, required, url;
      event = _arg.event, limit = _arg.limit;
      required = {
        event: event
      };
      optional = {
        limit: limit
      };
      params = generateParam({
        required: required,
        optional: optional
      });
      url = ("" + host + "/events/properties/top?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    eventProp.prototype.values = function(_arg) {
      var bucket, event, limit, name, optional, params, required, url;
      event = _arg.event, name = _arg.name, limit = _arg.limit, bucket = _arg.bucket;
      required = {
        event: event,
        name: name
      };
      optional = {
        limit: limit,
        bucket: bucket
      };
      params = generateParam({
        required: required,
        optional: optional
      });
      url = ("" + host + "/events/properties/values?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    return eventProp;

  })();

  funnels = (function() {
    function funnels(_arg) {
      this.secret = _arg.secret, this.api_key = _arg.api_key;
    }

    funnels.prototype.list = function() {
      var url;
      url = ("" + host + "/funnels/list?") + qs.call(this);
      return req({
        url: url
      });
    };

    return funnels;

  })();

  annotations = (function() {
    function annotations(_arg) {
      this.secret = _arg.secret, this.api_key = _arg.api_key;
    }

    annotations.prototype.list = function(_arg) {
      var from_date, params, to_date, url;
      from_date = _arg.from_date, to_date = _arg.to_date;
      params = {
        from_date: moment(from_date).format('YYYY-MM-DD'),
        to_date: moment(to_date).format('YYYY-MM-DD')
      };
      url = ("" + host + "/annotations/?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    annotations.prototype.create = function(_arg) {
      var date, description, params, url;
      date = _arg.date, description = _arg.description;
      params = {
        date: moment(date).format('YYYY-MM-DD HH:mm:ss'),
        description: description
      };
      url = ("" + host + "/annotations/create?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    annotations.prototype.update = function(_arg) {
      var date, description, id, params, url;
      id = _arg.id, date = _arg.date, description = _arg.description;
      params = {
        id: id,
        date: moment(date).format('YYYY-MM-DD HH:mm:ss'),
        description: description
      };
      url = ("" + host + "/annotations/update?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    annotations.prototype["delete"] = function(id) {
      var params, url;
      params = {
        id: id
      };
      url = ("" + host + "/annotations/delete?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    return annotations;

  })();

  segmentation = (function() {
    function segmentation(_arg) {
      this.secret = _arg.secret, this.api_key = _arg.api_key;
    }

    segmentation.prototype.segmentation = function(_arg) {
      var event, expression, from_date, limit, optional, params, required, to_date, type, unit, url;
      event = _arg.event, from_date = _arg.from_date, to_date = _arg.to_date, unit = _arg.unit, limit = _arg.limit, type = _arg.type, expression = _arg.expression;
      required = {
        event: event,
        from_date: moment(from_date).format('YYYY-MM-DD'),
        to_date: moment(to_date).format('YYYY-MM-DD')
      };
      optional = {
        unit: unit,
        limit: limit,
        type: type
      };
      params = generateParam({
        required: required,
        optional: optional
      });
      _.extend(params, expression);
      url = ("" + host + "/segmentation?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    segmentation.prototype.numeric = function(_arg) {
      var event, expression, from_date, optional, params, required, to_date, type, unit, url;
      event = _arg.event, from_date = _arg.from_date, to_date = _arg.to_date, unit = _arg.unit, type = _arg.type, expression = _arg.expression;
      required = {
        event: event,
        from_date: moment(from_date).format('YYYY-MM-DD'),
        to_date: moment(to_date).format('YYYY-MM-DD')
      };
      optional = {
        unit: unit,
        type: type
      };
      params = generateParam({
        required: required,
        optional: optional
      });
      _.extend(params, expression);
      url = ("" + host + "/segmentation/numeric?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    segmentation.prototype.sum = function(_arg) {
      var event, expression, from_date, optional, params, required, to_date, unit, url;
      event = _arg.event, from_date = _arg.from_date, to_date = _arg.to_date, unit = _arg.unit, expression = _arg.expression;
      required = {
        event: event,
        from_date: moment(from_date).format('YYYY-MM-DD'),
        to_date: moment(to_date).format('YYYY-MM-DD')
      };
      optional = {
        unit: unit
      };
      params = generateParam({
        required: required,
        optional: optional
      });
      _.extend(params, expression);
      url = ("" + host + "/segmentation/sum?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    segmentation.prototype.average = function(_arg) {
      var event, expression, from_date, optional, params, required, to_date, unit, url;
      event = _arg.event, from_date = _arg.from_date, to_date = _arg.to_date, unit = _arg.unit, expression = _arg.expression;
      required = {
        event: event,
        from_date: moment(from_date).format('YYYY-MM-DD'),
        to_date: moment(to_date).format('YYYY-MM-DD')
      };
      optional = {
        unit: unit
      };
      params = generateParam({
        required: required,
        optional: optional
      });
      _.extend(params, expression);
      url = ("" + host + "/segmentation/average?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    return segmentation;

  })();

  mp = (function() {
    function mp(config) {
      this.engage = __bind(this.engage, this);
      this.retention = __bind(this.retention, this);
      this.raw = __bind(this.raw, this);
      this.secret = config.secret, this.api_key = config.api_key;
      this.events = new events(config);
      this.eventProp = new eventProp(config);
      this.funnels = new funnels(config);
      this.annotations = new annotations(config);
      this.segmentation = new segmentation(config);
    }

    mp.prototype.raw = function(_arg, cb) {
      var bucket, event, expression, from_date, optional, params, required, to_date, url;
      from_date = _arg.from_date, to_date = _arg.to_date, event = _arg.event, expression = _arg.expression, bucket = _arg.bucket;
      from_date = moment(from_date).format('YYYY-MM-DD');
      to_date = moment(to_date).format('YYYY-MM-DD');
      required = {
        from_date: from_date,
        to_date: to_date
      };
      optional = {
        event: event,
        bucket: bucket
      };
      params = generateParam({
        required: required,
        optional: optional
      });
      _.extend(params, expression);
      url = ("" + rawhost + "/export?") + qs.call(this, params);
      if (cb && _.isFunction(cb)) {
        return request({
          url: url
        }, cb);
      } else {
        return request({
          url: url
        });
      }
    };

    mp.prototype.retention = function(_arg) {
      var born_event, event, expression, from_date, interval, interval_count, limit, optional, params, required, retention_type, to_date, unit, url;
      from_date = _arg.from_date, to_date = _arg.to_date, retention_type = _arg.retention_type, born_event = _arg.born_event, event = _arg.event, interval = _arg.interval, interval_count = _arg.interval_count, unit = _arg.unit, limit = _arg.limit, expression = _arg.expression;
      required = {
        from_date: moment(from_date).format('YYYY-MM-DD'),
        to_date: moment(to_date).format('YYYY-MM-DD')
      };
      optional = {
        retention_type: retention_type,
        born_event: born_event,
        event: event,
        interval: interval,
        interval_count: interval_count,
        unit: unit,
        limit: limit
      };
      params = generateParam({
        required: required,
        optional: optional
      });
      _.extend(params, expression);
      url = ("" + host + "/retention?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    mp.prototype.engage = function(_arg) {
      var distinct_id, optional, page, params, required, session_id, url, where;
      where = _arg.where, session_id = _arg.session_id, page = _arg.page, distinct_id = _arg.distinct_id;
      required = {};
      optional = {
        distinct_id: distinct_id,
        where: where,
        session_id: session_id,
        page: page
      };
      params = generateParam({
        required: required,
        optional: optional
      });
      url = ("" + host + "/engage/?") + qs.call(this, params);
      return req({
        url: url
      });
    };

    return mp;

  })();

  module.exports = function(config) {
    return new mp(config);
  };

}).call(this);
