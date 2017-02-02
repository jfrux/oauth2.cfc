/**
* @displayname oauth2 client access token
* @output false
* @hint The oauth2 access token object.
* @authors Joshua Rountree
* @website http://github.com/joshuairl/oauth2.cfc
* @purpose A ColdFusion Component to manage authentication using the OAuth2 protocol.
**/
component accessors="true" {

  /**
  * @getter true
  * @setter true
  * @type oauth2.client
  * @hint The client component
  **/
  property name="client_object";

  /**
  * @getter true
  * @setter true
  * @type string
  * @hint The access token for your requests.
  **/
  property name="token_prop";

  /**
  * @getter true
  * @setter true
  * @type string
  * @hint The access token expiration time
  **/
  property name="expires_in";

  /**
  * @getter true
  * @setter true
  * @type string
  * @hint the access token expires at
  **/
  property name="expires_at";

  /**
  * @getter true
  * @setter true
  * @type struct
  * @hint The parameters for access token
  **/
  property name="params";

  /**
  * @getter true
  * @setter true
  * @type struct
  * @hint The options for access token
  **/
  property name="options";

  /**
  * @getter true
  * @setter true
  * @type string
  * @hint The refresh_token
  **/
  property name="refresh_token";


  public oauth2.access_token function init(oauth2.client client_object,string token,struct opts = {}) {
    var options = arguments.opts;
    var loc = {};
    setclient_object(arguments.client_object);
    setToken_prop(arguments.token);

    if(structKeyExists(arguments,'opts')) {
      arrayEach(["refresh_token","expires_in","expires_at"],function(key,index) {
        if (structKeyExists(options,key)) {
          evaluate("set#key#(options[key])"); // probably a proper way to do this I'm sure.
          structDelete(options,key);
        }
      });
    }

    if(structKeyExists(options,'expires') AND !structKeyExists(variables,'expires_in')) {
      setExpires_in(options.expires);
    }

    if(!isNumeric(getExpires_at())) {
      if(isNumeric(getExpires_in())) {
        setExpires_at(getEpochTime() + getEpochTime(getExpires_in()));
      }
    }

    setOptions({
       'mode':structKeyExists(options,'mode') ? structDeleteAndReturn(options,'mode') : 'header',
       'header_format':structKeyExists(options,'header_format') ? structDeleteAndReturn(options,'header_format') : 'Bearer %s',
       'param_name':structKeyExists(options,'param_name') ? structDeleteAndReturn(options,'param_name') : 'access_token'
    });

    setParams(options);

    return this;
  }

  public function from_hash(oauth2.client client_object, struct props) {
    var newHash = duplicate(arguments.props);
    var accessToken = arguments.props.access_token;
    var client_object = {};
    structDelete(arguments.props,'access_token');
    var client_object = init(arguments.client_object,accessToken,arguments.props,newHash);
    return client_object;
  }

  private function getEpochTime() {
    var datetime = 0;
    if (ArrayLen(Arguments) is 0) {
      datetime = Now();
    }
    else {
      if (IsDate(Arguments[1])) {
        datetime = Arguments[1];
      } else {
        return arguments[1];
      }
    }
    return DateDiff("s", "January 1 1970 00:00", datetime);


  }

  private any function getParam(key) {
    if (structKeyExists(getParams(),key)) {
      return getParams()[key];
    } else {
      return false;
    };
  }

  public function does_expire() {
    !isEmpty(getExpires_at());
  }

  public function is_expired() {
    return (does_expire() && (getExpires_at() < getEpochTime()))
  }

  public oauth2.access_token function refresh(params = {}) {
    var opts = arguments.params;
    var client_object = getClient_object();
    if (isEmpty(getRefresh_token())) {
      throw(type="oauth2.no_refresh_token",message="You attempted to refresh a token without a `refresh_token`");
    }

    structAppend(opts,{
      'client_id': client_object.getId(),
      'client_secret': client_object.getSecret(),
      'grant_type': 'refresh_token',
      'refresh_token': getRefresh_token()
    },true);

    new_token = client_object.get_token(opts);
    new_token.setOptions(getOptions());
    if(isEmpty(new_token.getRefresh_token())) {
      new_token.setRefresh_token(getRefresh_token());
    }

    return new_token;
  }

  public struct function to_hash() {
    var currentParams = getParams();
    structAppend(currentParams,{
      'access_token': getToken_prop(),
      'refresh_token': getRefresh_token(),
      'expires_at': getExpires_at()
    },true)
    return currentParams;
  }

  public function request(verb,path,opts = {}) {
    var client_object = getClient_object();
    arguments.opts = structureOptions(arguments.opts);

    return client_object.request(argumentCollection=arguments);
  }

  public function get(path,opts={}) {
    arguments['verb'] = 'get';
    return request(argumentCollection=arguments);
  }

  public function post(path,opts={}) {
    arguments['verb'] = 'post';
    return request(argumentCollection=arguments);
  }

  public function put(path,opts={}) {
    arguments['verb'] = 'put';
    return request(argumentCollection=arguments);
  }

  public function patch(path,opts={}) {
    arguments['verb'] = 'patch';
    return request(argumentCollection=arguments);
  }

  public function delete(path,opts={}) {
    arguments['verb'] = 'delete';
    return request(argumentCollection=arguments);
  }

  public function getHeaders() {
    return {
      'Authorization': replace(getOption('header_format'),'%s',getToken_prop())
    }
  }

  //allows you to call getXXXX() on non-properties of this class that are stored in the params struct
  public any function OnMissingMethod(string missingMethodName,struct missingMethodArguments) {
    if (left(arguments.missingMethodName,3) EQ "get") {
      //return value response for params object;
      return getParam(replace(arguments.missingMethodName,'get',''));
    } else {
      return false;
    }
  }

  include "utils/struct_delete_and_return.cfm";

  public any function getOption(key) {
    var options = getOptions();

    if (structKeyExists(options,key)) {
      return options[key];
    } else {
      throw "Option not available.";
    }
  }

  private function structureOptions(struct opts) {
    var newOptions = arguments.opts;
    var selfOptions = getOptions();
    switch (selfOptions.mode) {
      case 'header':
        newOptions['headers'] = !structKeyExists(newOptions,'headers') ? {} : newOptions['headers'];
        structAppend(newOptions.headers,getHeaders());
        break;
      case 'query':
        newOptions['params'] = !structKeyExists(newOptions,'params') ? {} : newOptions['params'];
        newOptions['params'][selfOptions['param_name']] = token
        break;
      case 'body':
        newOptions['body'] = !structKeyExists(newOptions,'body') ? {} : newOptions['body'];
        if (isStruct(newOptions['body'])) {
          newOptions['body'][selfOptions['param_name']] = token
        } else {
          listAppend(newOptions['body'],'&#selfOptions['param_name']#=#getToken_prop()#','&');
        }
        break;
      default:
        throw(type="oAuth2.invalid_mode",message="invalid `mode` option of `#selfOptions.mode#` in `access_token`");
    }
    return newOptions;
  }
}
