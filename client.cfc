/**
* @displayname oauth2 client
* @output false
* @hint The oauth2 object.
* @authors Matt Gifford, Joshua Rountree
* @website http://www.mattgifford.co.uk/
* @purpose A ColdFusion Component to manage authentication using the OAuth2 protocol.
**/
component accessors="true"
{
  /**
  * @getter true
  * @setter true
  * @type string
  * @validate string
  * @validateParams { minLength=1 }
  * @hint The client ID for your application.
  **/
  property name="id";

  /**
  * @getter true
  * @setter true
  * @type string
  * @validate string
  * @validateParams { minLength=1 }
  * @hint The client secret for your application.
  **/
  property name="secret";

  /**
  * @getter true
  * @setter true
  * @type struct
  * @hint opts to create the client with
  **/
  property name="options" default=structNew();

  /**
  * @type http
  * @required false
  * @hint cfhttp connection object
  **/
  property name="connection";

  /**
  * @getter true
  * @setter true
  * @type string
  * @validate string
  * @validateParams { minLength=1 }
  * @hint The OAuth2 provider site host
  **/
  property name="site" default="/oauth/authorize";

  /**
  * @getter true
  * @setter true
  * @type string
  * @validate string
  * @validateParams { minLength=1 }
  * @hint ('/oauth/authorize') absolute or relative URL path to the Authorization endpoint
  **/
  property name="authorize_url" default="/oauth/authorize";

  /**
  * @getter true
  * @setter true
  * @type string
  * @validate string
  * @validateParams { minLength=1 }
  * @hint ('/oauth/token') absolute or relative URL path to the Token endpoint
  **/
  property name="token_url" default="/oauth/token";

  /**
  * @getter true
  * @setter true
  * @type string
  * @validate string
  * @validateParams { minLength=1 }
  * @hint ('post') HTTP method to use to request token ('get' or 'post')
  **/
  property name="token_method" default="post";

  /**
  * @getter true
  * @setter true
  * @type struct
  * @hint ('{}') Hash of connection options to pass to initialize CFHTTP
  **/
  property name="connection_opts" default=structNew();

  /**
  * @getter true
  * @setter true
  * @type numeric
  * @hint (5) maximum number of redirects to follow
  **/
  property name="max_redirects" default=5;

  /**
  * @getter true
  * @setter true
  * @type boolean
  * @hint (true) whether or not to raise an OAuth2::Error
  **/
  property name="raise_errors" default=true;

  /**
  * @hint I return an initialized instance.
  * @description I return an initialize oauth2 object instance.
  **/
  public oauth2.client function init( required string client_id, required string client_secret, struct options ) {
    var default_options = {
      authorize_url    : '/oauth/authorize',
      token_url        : '/oauth/token',
      token_method     : 'post',
      connection_opts  : {},
      max_redirects    : 5,
      raise_errors     : true
    };

    var opts = duplicate(arguments.options);
    var ssl = false;
    structAppend(
      default_options,
      opts //passed in options minus a couple
      ,true //true override defaults
    )
    //merge options with defaults
    setOptions(default_options);

    getOption('connection_opts')['ssl'] = ssl;

    setId(arguments.client_id);
    setSecret(arguments.client_secret);
    setToken_method(getOptions().token_method);
    setToken_url(getOptions().token_url);
    setAuthorize_url(getOptions().authorize_url);
    setSite(getOptions().site);

    ssl = structKeyExists(opts,'ssl') ? opts.ssl : false;
    structDelete(opts,'ssl');

    return this;
  };

  //MAKE STANDARD HTTP REQUEST
  public function request(verb,theUrl,opts = {}) {
    var conn = new Http(getconnection_opts());
    var requestUrl = "";
    var response = {};

    if (verb EQ "post") {
      //add body fields for post
      if (structCount(arguments.opts.fields)) {
        for (key in arguments.opts.fields) {
          conn.addParam(type='formfield',name=key,value=arguments.opts.fields[key]);
        }

        structDelete(arguments.opts,'fields');
      }
    }

    // add headers
    if (structCount(arguments.opts.headers)) {
      for ((key) in arguments.opts.headers) {
        conn.addParam(type='header',name=key,value=arguments.opts.headers[key]);
      }

      structDelete(arguments.opts,'headers');
    }

    if(arguments.theUrl CONTAINS "http") {
      requestUrl = arguments.theUrl;
    } else {
      requestUrl = build_url(arguments.path,arguments.opts);
    }

    conn.setUrl(requestUrl);
    conn.setMethod(verb);
    conn.setRedirect(true);
    httpResponse = conn.send().getPrefix();
    response = new OAuth2.Response(httpResponse,arguments.opts);

    if (isEmpty(response.status())) {
      throw (
        message = "Connection to the oAuth2 provider failed.",
        type = "oauth2.no_response"
      )
    }
    if (listFind('301,302,303,307',response.status())) {
      //todo redirect logic here
      // since setRedirect(true) it shouldn't ever show this
      abort;
    } else if (isValid("range", response.status(), 200, 299)) {
      return response
    } else if (isValid("range", response.status(), 400,499)) {
      errorObj = deserializeJson(response.body());
      throw (
        message = errorObj.error & " - " & errorObj.error_description,
        type = "oauth2.#errorObj.error#",
        detail = response.errorDetail & "- " & requestUrl,
        errorCode = response.status()
      )
    } else if (isValid("range", response.status(), 500,599)) {
      writeOutput(response.body());
      abort;
    } else {
      throw "Unhandled status code value of #response.status_code#";
    }

  }

  //GET ACCESS_TOKEN
  public oauth2.access_token function get_token(params = {}, access_token_opts = {}, access_token_class = 'oauth2.access_token') {
    var opts = {};
    var headers = {};
    var parsed = {};
    var access_token = {};
    opts['raise_errors'] = getOption('raise_errors');
    opts['parse'] = structkeyExists(arguments,'params') && structkeyExists(arguments.params,'parse') ? arguments.params.parse : false;

    if (structKeyExists(arguments.params,'parse'))
      structDelete(arguments.params,'parse');
    if (getToken_method() EQ "post") {
      headers = structKeyExists(arguments.params,'headers') ? params.headers : {};
      opts['fields'] = arguments.params;
      opts['headers'] = { 'Content-Type': 'application/x-www-form-urlencoded' };
      structAppend(opts.headers,headers,true);
    } else {
      opts['params'] = arguments.params;
    }

    response = request(getOption('token_method'),build_token_url(),opts);
    parsed = response.parsed();

    if (getOption('raise_errors') && !(isStruct(parsed) && structKeyExists(parsed,'access_token'))) {
      throw(type="oAuth2.UnknownError",message="Token could not be found in the response body.");
      return false;
    }
    structAppend(parsed,arguments.access_token_opts);

    access_token = createObject("component",arguments.access_token_class).from_hash(this,parsed);
    return access_token;
  }

  //STRATEGY METHODS
  public function password() {
    return new oauth2.strategy.password(this);
  }

  public function auth_code() {
    return new oauth2.strategy.auth_code(this);
  }

  //BUILD URL HELPERS
  public function build_url(path,params = {}) {
    var theUrl = "#getSite()##arguments.path#?#buildParamString(arguments.params)#";
    return theUrl;
  };

  public function build_authorize_url(params = {}) {
    var theUrl = "#getSite()##getAuthorize_url()#?#buildParamString(arguments.params)#";
    return theUrl;
  };

  public function build_token_url(params = {}) {
    var theUrl = "#getSite()##getToken_url()#";

    if (structCount(arguments.params) GT 0) {
      theUrl &= "?" & buildParamString(arguments.params);
    }

    return theUrl;
  };

  public any function getOption(key) {
    var options = getOptions();

    if (structKeyExists(options,key)) {
      return options[key];
    } else {
      throw "Option not available.";
    }
  }

  include "utils/build_query_string.cfm";
  include "utils/struct_delete_and_return.cfm";

}
