component accessors="true" {
  /**
  * @getter true
  * @setter true
  * @type struct
  * @hint The response from cfhttp request
  **/
  property name="response";

  /**
  * @getter true
  * @setter true
  * @type struct
  * @hint The options passed into the response class
  **/
  property name="options";


  /**
  * @getter true
  * @setter true
  * @type any
  * @hint parsed
  **/
  property name="parsed";

  /**
  * @hint Initializes a Response instance
  **/
  variables['parsed'] = "";
  public oauth2.response function init(struct response, opts = {}) {
    setResponse(arguments.response);
    setOptions(arguments.opts);
    structAppend(getOptions(),{ 'parse': 'automatic' },false);
    
    return this;
  }

  public function headers() {
    return structKeyExists(getResponse(),'responseheader') ? getResponse()['headers'] : {};
  }

  public function content_type() {
    return structKeyExists(getResponse(),'mimetype') ? getResponse()['mimetype'] : {};
  }

  public function status() {
    return structKeyExists(getResponse(),'status_code') ? getResponse()['status_code'] : {};
  }

  public function body() {
    return structKeyExists(getResponse(),'filecontent') ? getResponse()['filecontent'] : '';
  }

  public function parsed() {
    if (structKeyExists(variables.PARSERS,parser())) {
      if (isEmpty(getParsed())) {
        setParsed(PARSERS[parser()](body()));
      }
      return getParsed();
    }
  }

  // determines the parser that will be used to supply the content to parsed()
  public function parser() {
    if (structKeyExists(variables.PARSERS,getOptions()['parse'])) {
      return getOptions()['parse'];
    }
    return CONTENT_TYPES[content_type()];
  }

  public function register_parser(string key, array mime_types, function method) {
    variables.PARSERS[arguments.key] = method;
  }

  variables.PARSERS = {
    'json': function(body) {
      return deserializeJson(arguments.body);
    },
    'query': function(body) {
      var myStruct = StructNew();
      var i = 0;
      var delimiter = ",";
      var tempList = arrayNew(1);
      if (ArrayLen(arguments) gt 1) {
        delimiter = arguments[2];
      }
      tempList = listToArray(list, delimiter);
      for (i=1; i LTE ArrayLen(tempList); i=i+1){
        if (not structkeyexists(myStruct, trim(ListFirst(tempList[i], "=")))) {
          StructInsert(myStruct, trim(ListFirst(tempList[i], "=")), trim(ListLast(tempList[i], "=")));
        }
      }
      return myStruct;
      return listTo(arguments.body);
    }
  }

  //CONTENT TYPE ASSIGNMENTS FOR VARIOUS HTTP CONTENT TYPES
  variables.CONTENT_TYPES = {
    'application/json': 'json',
    'text/javascript': 'json',
    'application/x-www-form-urlencoded': 'query',
    'text/plain': 'text',
  }
}
