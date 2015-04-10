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
  property name="options";

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
  property name="site" default="";

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
  property name="connection_opts";

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
    var ssl = true;
    structAppend(
      opts,
      default_options
      ,false
    )

    setOptions(opts);

    //merge options with defaults
    setId(arguments.client_id);
    setSecret(arguments.client_secret);
    setToken_method(getOption('token_method'));
    setToken_url(getOption('token_url'));
    setAuthorize_url(getOption('authorize_url'));
    setSite(getOption('site'));
    setConnection_opts(getOption('connection_opts'));

    structDelete(opts,'connection_opts');

    getConnection_opts()['ssl'] = ssl;

    ssl = structKeyExists(opts,'ssl') ? opts.ssl : false;
    structDelete(opts,'ssl');

    return this;
  };

  //MAKE STANDARD HTTP REQUEST
  public function request(verb,theUrl,opts = {}) {
    var loc = {};
    loc.request = {};
    loc.request.method = UCASE(arguments.verb);
    if (structKeyExists(arguments.opts,'headers')) {
      loc.request.headers = arguments.opts.headers;
      structDelete(arguments.opts,'headers');
    }

    if (structKeyExists(arguments.opts,'body')) {
      loc.request.body = CreateObject("java", "java.lang.String").Init(JavaCast("string",arguments.opts.body));
      structDelete(arguments.opts,'body');
    }

    if (structKeyExists(arguments.opts,'fields')) {
      loc.request.fields = arguments.opts.fields;
      structDelete(arguments.opts,'fields');

      loc.requestBody = "";
      //add body fields for post
      for (key in loc.request.fields) {
        loc.requestBody = loc.requestBody & key & "=" & loc.request.fields[key] & "&";
        <!--- loc.conn.addParam(type='formfield',name=key,value=arguments.opts.fields[key]); --->
      }

      //convert to java string object
      loc.request.body = CreateObject("java", "java.lang.String").Init(JavaCast("string",loc.requestBody));
    }

    if(arguments.theUrl CONTAINS "http") {
      loc.requestUrl = arguments.theUrl;
    } else {
      loc.requestUrl = build_url(arguments.path,arguments.opts);
    }

    loc.objUrl = createobject("java","java.net.URL").init(loc.requestUrl);
    //OPENS CONNECTION
    loc.conn = loc.objUrl.openConnection();
    loc.conn.setFollowRedirects(true);
    //configure the request
    if (structKeyExists(loc.request,'body')) {
      loc.conn.setDoOutput(true);
    }

    loc.conn.setUseCaches(false);
    loc.conn.setRequestMethod(loc.request.method);

    if (loc.request.method EQ "POST" AND structKeyExists(loc.request,'fields') AND structCount(loc.request.fields)) {
      loc.conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded;");
    }

    // add headers
    if (structCount(loc.request.headers)) {
      for ((key) in loc.request.headers) {
        loc.conn.setRequestProperty(key, loc.request.headers[key]);
      }
    }

    if (structKeyExists(loc.request,'body')) {
      loc.ostream = loc.conn.getOutputStream();
      if (structKeyExists(loc.request,'body')) {
        loc.ostream.write(loc.request.body.getBytes());
      }
      loc.ostream.flush();
      loc.ostream.Close();
    }
    loc.responseObj = {};

    //TRY THE REQUEST...
    try {
      loc.inS =createobject("java","java.io.InputStreamReader").init(loc.conn.getInputStream());

    } catch(any errorObj) {
      loc.responseObj.status_code = loc.conn.getResponseCode();
      if (isEmpty(loc.responseObj.status_code)) {
        throw (
          message = "Connection to the oAuth2 provider failed.",
          type = "oauth2.no_response"
        )
      }
      if (listFind('301,302,303,307',loc.responseObj.status_code)) {

        abort;
      } else if (isValid("range", loc.responseObj.status_code, 200, 299)) {
        return response
      } else if (isValid("range", loc.responseObj.status_code, 400,499)) {

        if (loc.responseObj.status_code EQ "401") {
          errorObj = "Unauthorized";
        }
        throw (
          message = errorObj,
          type = "oauth2.#loc.responseObj.status_code#",
          errorCode = loc.responseObj.status_code
        )
      } else if (isValid("range", loc.responseObj.status_code, 500,599)) {
        <!--- writeOutput(""); --->
        abort;
      } else {
        throw "Unhandled status code value of #response.status_code#";
      }
    }
    loc.responseObj['Header'] = "";

    loc.responseObj['Responseheader'] = {};

    loc.respHeaders = loc.conn.getHeaderFields().entrySet();
    loc.respHeadersArray = loc.respHeaders.toArray();
    for (i=1;i <= arrayLen(loc.respHeadersArray); i++) {
      loc.respHeaderValue = "";
      if (isNull(loc.respHeadersArray[i].getKey())) {
        //split http version and status code;
        loc.respHeaderKey = "";
        loc.respHeaderValue = loc.respHeadersArray[i].getValue()[1];
        loc.responseObj['Header'] = loc.responseObj['Header'] & "#loc.respHeaderKey#: #loc.respHeaderValue#";
        loc.responseObj.responseheader['Http-Version'] = listFirst(loc.respHeaderValue," ");
        loc.responseObj.responseheader['Status_Code'] = getToken(loc.respHeaderValue,2," ");
        loc.responseObj['Statuscode'] = right(loc.respHeaderValue,len(loc.respHeaderValue)-find(" ",loc.respHeaderValue))
      } else {
        loc.respHeaderKey = loc.respHeadersArray[i].getKey();
        loc.respHeaderValue = loc.respHeadersArray[i].getValue()[1];
        loc.responseObj.responseheader[loc.respHeaderKey] = loc.respHeaderValue;

        loc.responseObj['Header'] = loc.responseObj['Header'] & "#loc.respHeaderKey#: #loc.respHeaderValue#";

        if (loc.respHeaderKey EQ "Content-Type") {
          loc.responseObj['Mimetype'] = listFirst(loc.respHeaderValue,';');
        }
      }

    }

    <!--- loc.responseObj['status_code'] = loc.conn.getResponseCode(); --->
    loc.inVar = createObject("java","java.io.BufferedReader").init(loc.inS);

    loc.responseObj['Filecontent'] = "";
    <!--- loc.builder = createObject("java","java.lang.StringBuilder").init(javacast("int",1000)); --->
    loc.line    = "";
    do
    {
       loc.line = loc.inVar.readLine();
       loc.lineCheck = isDefined("loc.line");
       if(loc.lineCheck)
       {
         loc.responseObj.filecontent = loc.responseObj.filecontent & loc.line;
       }
    } while(loc.lineCheck);


    <!--- httpResponse = conn.send().getPrefix(); --->
    <!--- if(verb EQ "put") {

    } --->
    <!--- writeDump(var=#loc.responseObj#,abort=true); --->
    loc.response = new OAuth2.Response(loc.responseObj,arguments.opts);

    return loc.response;
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

    headers = structDeleteAndReturn(arguments.params,'headers');
    opts['headers'] = { 'Content-Type': 'application/x-www-form-urlencoded' };

    if (isDefined("headers")) {
      structAppend(opts.headers,headers,true);
    }

    if (getToken_method() EQ "post") {
      // headers = structKeyExists(arguments.params,'headers') ? headers : {};
      opts['fields'] = arguments.params;
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

  //getter for authorize_url
  public function authorize_url(struct params = {}) {
    return build_authorize_url(argumentCollection=arguments);
  }

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
