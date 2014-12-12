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
  public oauth2.client function init(
    required string client_id,
    required string client_secret,
    struct options
  )
  {
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

    setid(arguments.client_id);
    setsecret(arguments.client_secret);
    setToken_method(getOptions().token_method);
    setToken_url(getOptions().token_url);
    setAuthorize_url(getOptions().authorize_url);
    setSite(getOptions().site);

    ssl = structKeyExists(opts,'ssl') ? opts.ssl : false;
    structDelete(opts,'ssl');




    return this;
  };

  public http function httpConnection() {
    var connection = new Http(getconnection_opts());

    return connection;
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

  public function request(verb,theUrl,opts = {}) {
    var conn = httpConnection();
    var requestUrl = "";
    var response = {};

    if (verb EQ "post") {
      // conn.addParam(type="body",value=serializeJson(arguments.opts.body));
      if (structCount(arguments.opts.fields)) {
        for (key in arguments.opts.fields) {
          conn.addParam(type='formfield',name=key,value=arguments.opts.fields[key]);
        }
      }
    }

    if (structKeyExists(arguments.opts,'params')) {
      for (key in arguments.opts.params) {
        conn.addParam(arguments.opts.params[key]);
        writeDump(var=arguments.opts.params,abort=true);
      }
      requestUrl = arguments.theUrl;
    } else {
      requestUrl = arguments.theUrl;
    }
    conn.setUrl(requestUrl);
    conn.setMethod(verb);
    conn.setRedirect(true);

    response = conn.send().getPrefix();
    writeDump(var=response,abort=true);
    if (listFind('301,302,303,307',response.status_code)) {
      //todo redirect logic here
      // since setRedirect(true) it shouldn't ever show this
      abort;
    } else if (isValid("range", response.status_code, 200, 299)) {
      return response.filecontent
    } else if (isValid("range", response.status_code, 400,599)) {
      errorObj = deserializeJson(response.filecontent);
      throw (
        message = errorObj.error & " - " & errorObj.error_description,
        type = "oauth2.#errorObj.error#",
        detail = response.errorDetail & "- " & requestUrl,
        errorCode = response.status_code
      )
    } else {
      throw "Unhandled status code value of #response.status_code#";
    }

  }

  public function get_token(params = {}, access_token_opts = {}, access_token_class = 'oauth2.access_token') {
    var opts = {};
    var headers = {};
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
  }

  public function password() {
    return new oauth2.strategy.password(this);
  }

  public function auth_code() {
    return new oauth2.strategy.auth_code(this);
  }

  public any function getOption(key) {
    var options = getOptions();

    if (structKeyExists(options,key)) {
      return options[key];
    } else {
      throw "Option not available.";
    }
  }
  /**
  * @hint I return the URL as a string which we use to redirect the user for authentication.
  * @description I return the URL as a string which we use to redirect the user for authentication.
  * @parameters A structure containing key / value pairs of data to be included in the URL string.
  **/
  public string function buildRedirectToAuthURL( struct parameters={} ) {
    return getAuthEndpoint() & '?client_id=' & getClient_id() & '&redirect_uri=' & getRedirect_uri() & buildParamString(argScope = arguments.parameters);
  }

  /**
  * @hint I make the HTTP request to obtain the access token.
  * @description I make the HTTP request to obtain the access token.
  * @code The code returned from the authentication request.
  **/
  public struct function makeAccessTokenRequest( required string code ) {
    var stuResponse = {};
    httpService = new http();
    httpService.setMethod("post");
    httpService.setCharset("utf-8");
    httpService.setUrl(getAccessTokenEndpoint());
    httpService.addParam(type="formfield", name="client_id", 	 value="#getClient_id()#");
    httpService.addParam(type="formfield", name="client_secret", value="#getClient_secret()#");
    httpService.addParam(type="formfield", name="code", 		 value="#arguments.code#");
    httpService.addParam(type="formfield", name="redirect_uri",  value="#getRedirect_uri()#");
    result = httpService.send().getPrefix();
    if('200' == result.ResponseHeader['Status_Code']) {
      stuResponse.success = true;
      stuResponse.content = result.FileContent;
    } else {
      stuResponse.success = false;
      stuResponse.content = result.Statuscode;
    }
    return stuResponse;
  }

  /**
  * @hint I return a string containing any extra URL parameters to concatenate and pass through when authenticating.
  * @description I return a string containing any extra URL parameters to concatenate and pass through when authenticating.
  * @argScope A structure containing key / value pairs of data to be included in the URL string.
  **/
  public string function buildParamString( struct params={} ) {
    var strURLParam = '';
    if(structCount(arguments.params)) {
      for (key in arguments.params) {
        if(listLen(strURLParam)) {
          strURLParam = strURLParam & '&';
        }
        strURLParam = strURLParam & lcase(key) & '=' & trim(arguments.params[key]);
      }
      strURLParam = '&' & strURLParam;
    }
    return strURLParam;
  }

}
