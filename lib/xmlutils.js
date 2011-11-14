/**
 * # xmlutils
 *
 * Copyright (c)2011, by FeeFighters <samurai@feefighters.com>
 *
 * Utitilities for parsing Samurai XML responses. These utilities are not 
 * general-purpose XML parsers and generators. Some of them can be quite useful
 * outside the Samurai context, but there's no guarantee of that.
 *
 * In general, you shouldn't need to touch these methods yoursef ever, unless
 * you are considering developing Samurai.
 *
 * @author FeeFighters <samurai@feefighters.com>
 * @license MIT (see LICENSE)
 */

var xmlutils = exports;

/**
 * ## getTagRe(tagName)
 * *Generate regex for parsing a single tag*
 *
 * @param {String} tagName The exact tag name as it appears in the XML
 * @returns {RegExp} Regular expresson object that will parse the given tag
 * @private
 */
function getTagRe(tagName) {
  return new RegExp('<(' + tagName + ')(?:>| ([^>]+)>)([^<]*)</' + tagName + '>', 'g');
}

/**
 * # matchAll(s, rxp)
 * *Run a regex multiple times until matches are exhausted*
 *
 * @param {String} s Source string
 * @param {RegExp} rxp RegExp object to run on the source
 * @returns {Array} Array of results
 * @private
 */
function matchAll(s, rxp) {
  var matches = [];
  var attrRe = /([a-zA-Z][a-zA-Z0-9_\-]*)="([^"]+)"/g;
  var match;
  var digested;
  var attrs;
  var attrMatch;
  var attribute;
  var value;
  var elements;

  match = rxp.exec(s);

  while (match) {
    // Set up the fresh `digested` object
    digested = {
      name: '',
      attributes: {},
      content: ''
    };

    // Extract only the relevant parts
    elements = match.slice(1, match.length);

    // Extract name and content
    digested.name = elements[0];
    digested.content = elements[2];

    // Extract attributes
    attrs = elements[1];

    attrMatch = attrRe.exec(attrs);

    // Process attributes
    while(attrMatch) {
      attribute = attrMatch[1];
      value = attrMatch[2];
      if (attribute && value) {
        digested.attributes[attribute] = value;
      }
      attrMatch = attrRe.exec(attrs);
    }

    matches.push(digested);
    match = rxp.exec(s);
  }

  return matches;
}

/**
 * ## getInnerXML(xml, tagName)
 * *Return raw inner XML of a node with a given tag name*
 *
 * This only searches inside the first match.
 *
 * @param {String} xml Source XML
 * @param {String} tagName Name of the tag for which to retrun inner XML
 * @returns {String} Inner XML contents for the first matched tag
 * @private
 */
function getInnerXML(xml, tagName) {
  var openTagRe = new RegExp('<' + tagName + '[^>]*>');
  var closeTagRe = new RegExp('</' + tagName + '>');
  var closedMatch;
  var startPos = 0;
  var substring;

  // Go to first match
  openTagRe.exec(xml);

  // Remember position and get slice of XML withotu the text before open tag
  startPos = openTagRe.lastIndex;
  substring = xml.slice(startPos);

  // Find closing tag in the substring
  closedMatch = closeTagRe.exec(substring);
  
  return xml.slice(startPos, closedMatch.index);
}

/**
 * ## xmlutils.toInt(s)
 * *Convert a string to integer*
 *
 * @param {String} s String to be parsed
 * @returns {Number} Converted integer
 */
xmlutils.toInt = function(s) {
  return parseInt(s, 10);
};

/**
 * ## xmlutils.toFloat(s)
 * *Convert string to a float*
 *
 * @param {String} s String to convert
 * @returns {Number} Converted float
 */
xmlutils.toFloat = function(s) {
  return parseFloat(s);
};

/**
 * ## xmlutils.toDate(s)
 * *Convert a string to Date object*
 *
 * @param {String} s String to be parsed
 * @returns {Date} Converted date
 */
xmlutils.toDate = function(s) {
  return new Date(s);
};

/**
 * ## xmlutils.toBool(s)
 * *Convert a string to Bool*
 *
 * This function treats `'true'` as `true`, and everything else as false.
 *
 * @param {String} s String to be parsed
 * @returns {Bool} Converted boolean
 */
xmlutils.toBool = function(s) {
  return s === 'true' ? true : false;
};

/**
 * ## xmlutils.toString(s)
 * *Pass-through function that does nothing*
 *
 * @param {String} s Strning to be passed through
 * @returns {String} Same string that came in
 */
xmlutils.toString = function(s) {
  return s;
};

/**
 * ## xmlutils.extractData(xml, recipe)
 * *Extract data from XML string using recipe mappings*
 *
 * Recipe object contains a mapping between tag names and coercion functions
 * like `xmlutils.toInt` and `xmlutils.toDate`. Each key in the recipe object
 * will be treated as a valid tag name, and searched for within the XML. Data
 * found within the XML string will be coerced and assigned to a key in the
 * result object. The key name in the result object will match the key name
 * from the recipe object.
 *
 * An example recipe object:
 *
 *     {
 *       'payment_method_token': xmlutils.toString,
 *       'created_at': xmlutils.toDate,
 *       ....
 *     }
 *
 * A recipe may contain a special key '@' that can hold the name of the 
 * top-level node that should be searched (otherwise the recipe is applied to 
 * the whole XML source. For example:
 *
 *     {
 *       '@': 'payment_method',
 *       .....
 *     }
 *
 * @param {String} xml The source XML string
 * @param {Object} recipe The recipe object
 * @returns {Object} Name-value pairs of extracted data
 */
xmlutils.extractData = function(xml, recipe) {
  var result = {};

  // Should we only parse a single node?
  if (recipe['@']) {
    xml = getInnerXML(xml, recipe['@']);
  }

  Object.keys(recipe).forEach(function(key) {
    if (key === '@') {
      // Ignore this key
      return;
    }

    // Get the Regex for the recipe
    var rxp = getTagRe(key);
    var matches = matchAll(xml, rxp);

    matches.forEach(function(match) {
      if (!result.hasOwnProperty(key)) {
        result[key] = recipe[key](match.content);
      }
    });

    // If there's only one match, then return the single match w/o array
    if (result[key] && result[key].length < 2) {
      result[key] = result[key][0];
    }

  });

  return result;
};

/**
 * ## xmlutils.hasMessages(xml)
 * *Checks the XML to see if there is a `<messsages>` block*
 *
 * Returns `true` if there is a `<messages>` block.
 * 
 * @param {String} xml The XML string
 * @returns {Boolean} Whether it found the `<messages>` block
 */
xmlutils.hasMessages = function(xml) {
  return Boolean((/<messages[^>]*>/).exec(xml));
};

/**
 * ##xmlutils.extractMessages(xml)
 * *Extract messages from XML string*
 *
 * The messages can be of the following classes:
 *
 *  + _error_: errors and declines
 *  + _info_: success and other information
 * 
 * The messages will also have a context in which it was transmitted, and the 
 * message that describes the details.
 *
 * The return object may look like this:
 *
 *     {
 *       error: [{'input.card_number': 'failed_checksum'}]
 *     }
 *
 * @param {String} xml The XML string to be parsed
 * @returns {Array} Array of error messages.
 */
xmlutils.extractMessages = function(xml) {
  var matches = matchAll(xml, getTagRe('message'));
  var messages = [];

  matches.forEach(function(match) {
    var message = {};

    message.cls = match.attributes.subclass;
    message.context = match.attributes.context;
    message.key = match.attributes.key;
    message.text = match.content;

    messages.push(message);
  });

  return messages;
};

/**
 * ## xmlutils.decamelize(s)
 * *Converts 'CamelCase' to 'camel_case'*
 *
 * @param {String} s String to convert
 * @returns {String} Decamelized string
 */
xmlutils.decamelize = function(s) {
  s = s.replace(/^[A-Z]/, function(match) {
    return match.toLowerCase();
  });
  s = s.replace(/[A-Z]/g, function(match) {
    return '_' + match.toLowerCase();
  });
  return s;
};

/**
 * ## xmlutils.toXML(o, [topLevel], [keys])
 * *Shallow conversion of JavaScript object to XML*
 *
 * This method converts each key to a single XML node and converts the contents
 * of the key to a text node by calling `toString` on it.
 *
 * Optionally, the whole XML string can be wrapped in a top-level tag.
 *
 * This function _does not_ care about the order of keys, so if you need the
 * nodes to be in a certain order, you should supply an array of keys.
 *
 * @param {Object} o Object to be converted
 * @param {String} [topLevel] Top level tag
 * @param {Array} [keys] Array of keys to use so that nodes are ordered
 * @returns {String} XML version of the object
 */
xmlutils.toXML = function(o, topLevel, keys) {
  var xml = '';

  // Was topLevel arg skipped?
  if (typeof topLevel != 'string') {
    keys = topLevel;
    topLevel = null;
  } else {
    xml += '<' + xmlutils.decamelize(topLevel) + '>\n';
  }

  keys = keys || Object.keys(o);

  keys.forEach(function(key) {
    var tagName = xmlutils.decamelize(key);
    xml += '<' + tagName + '>' + o[key].toString() + '</' + tagName + '>\n';
  });

  if (topLevel) {
    xml += '</' + xmlutils.decamelize(topLevel) + '>\n';
  }
  
  return xml;
};

/**
 * ## xmlutils.toSamurai(o, mappings)
 * *Remaps the Samurai field names to Samurai node names in an object*
 *
 * Given an object with Samurai field names, this method converts only the 
 * fields found in MAPPINGS and renames the fields to Samurai node names 
 * returning a new object with the renamed fields.
 *
 * Example:
 *
 *     var samuraiObj = {
 *        fullName: 'Foo',
 *        lastName: 'Bar',
 *        year: 2012
 *     }
 *     xmlutils.toSamurai(samuraiObj, samurai.MAPPINGS);
 *     // returns: 
 *     //   {
 *     //     fullName: 'Foo',
 *     //     lastName: 'Bar',
 *     //     expiry_year: 2012
 *     //   }
 *
 * @param {Object} o Samurai object
 * @param {Object} mappings The mappings for he field names
 * @returns {Object} Object with remapped fields
 */
xmlutils.toSamurai = function(o, mappings) {
  var remapped = {};

  Object.keys(o).forEach(function(key) {
    if (mappings.hasOwnProperty(key)) {
      remapped[mappings[key]] = o[key];
    } else {
      remapped[key] = o[key];
    }
  });

  return remapped;
};
