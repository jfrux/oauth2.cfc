# oauth2.cfc

A ColdFusion Component (CFC) wrapper for the OAuth 2.0 specification.

## Preface
Some of this documentation may not be completely functional.  THe basis of consuming an oAuth2 Provider is covered in the current codebase but may have compatibily issues with some versions of ACF or Railo.

I had to opt out of using CFHTTP due to some versions of ACF / Railo not providing proper SSL support.  Since most OAuth2 Providers now have strict SSL requirements I've chosen to implement roughly with java::net::URL method. 

## Installation
Clone or download and extract the directory into your component directory under a directory titled 'oauth2'.
Create a per application mapping such as:
```javascript
// Application.cfc
this.mappings["/oauth2"] = "/my_components/oauth2";
```

## Resources
* [View Source on GitHub][code]
* [Report Issues on GitHub][issues]
* [Read More at the Wiki][wiki]

[code]: https://github.com/joshuairl/oauth2.cfc
[issues]: https://github.com/joshuairl/oauth2.cfc/issues
[wiki]: https://wiki.github.com/joshuairl/oauth2.cfc

## Usage Examples

### Install Example
```javascript
// Application.cfc
this.mappings["/oauth2"] = "/my_components/oauth2";
```

### Client Instantiation
```javascript
oauth2client = new oauth2.client(
  client_id = '1201203123123',
  client_secret = 'jkf32ifj023fj102ijfdk12odk'), 
  options = { 
    site: 'https://example.com', // auth site base url
    authorize_url: '/oauth/authorize', // relative or absolute path to authorize
    token_url: '/oauth/token'  // relative or absolute path to get token
  }
);
```

### Username / Password Flow Example
```javascript
access_token = oauth2client.password().get_token(session.username, session.password);
```

### AuthCode Flow Example
```javascript
authorizeUrl = oauth2client.auth_code().getAuthorize_url({ redirect_url: 'http://localhost:8080/oauth2/callback' });
// returns "https://example.com/oauth/authorization?response_type=code&client_id=client_id&redirect_uri=http://localhost:8080/oauth2/callback"

location(authorizeUrl); //redirect user to authorize_url

//once they arrive at your callback url you will need to request the token with your retrieved code.
token = oauth2client.auth_code().get_token(code = 'authorization_code_value', redirect_uri = 'http://localhost:8080/oauth2/callback', headers = {'Authorization' => 'Basic some_password'})
response = token.get('/api/resource', params = { 'query_foo' = 'bar' })
writeDump(var="#response#");
// returns OAuth2::Response
```

## OAuth2::Response
The AccessToken methods #get, #post, #put and #delete and the generic #request
will return an instance of the #OAuth2::Response class.

This instance contains a #parsed method that will parse the response body and
return a Hash if the Content-Type is application/x-www-form-urlencoded or if
the body is a JSON object.  It will return an Array if the body is a JSON
array.  Otherwise, it will return the original body string.

The original response body, headers, and status can be accessed via their
respective methods.

## OAuth2::AccessToken
If you have an existing Access Token for a user, you can initialize an instance
using various class methods including the standard new, from_hash (if you have
a hash of the values), or from_kvform (if you have an
application/x-www-form-urlencoded encoded string of the values).

## OAuth2::Error
On 400+ status code responses, an OAuth2::Error will be raised.  If it is a
standard OAuth2 error response, the body will be parsed and #code and #description will contain the values provided from the error and
error_description parameters.  The #response property of OAuth2::Error will
always contain the OAuth2::Response instance.

If you do not want an error to be raised, you may use :raise_errors => false
option on initialization of the client.  In this case the OAuth2::Response
instance will be returned as usual and on 400+ status code responses, the
Response instance will contain the OAuth2::Error instance.

## Authorization Grants
Currently the Authorization Code, Implicit, Resource Owner Password Credentials, Client Credentials, and Assertion
authentication grant types have helper strategy classes that simplify client
use.  They are available via the #auth_code, #implicit, #password, #client_credentials, and #assertion methods respectively.

TODO: THIS SECTION NEEDS TESTING

```javascript
auth_url = oauth2client.auth_code().authorize_url(:redirect_uri => 'http://localhost:8080/oauth/callback');
token = oauth2client.auth_code().get_token('code_value', :redirect_uri => 'http://localhost:8080/oauth/callback');

auth_url = oauth2client.implicit().authorize_url(:redirect_uri => 'http://localhost:8080/oauth/callback');
//get the token params in the callback and
token = token.from_kvform(oauth2client, query_string);

token = oauth2client.password().get_token('username', 'password');

token = oauth2client.client_credentials().get_token();

token = oauth2client.assertion().get_token(assertion_params);
```

If you want to specify additional headers to be sent out with the
request, add a 'headers' hash under 'params':

```javascript
token = oauth2client.auth_code().get_token(
    code = 'code_value',
    redirect_uri = 'http://localhost:8080/oauth/callback', 
    headers = {'Some': 'Header'}
);
```

You can always use the #request method on the OAuth2::Client instance to make
requests for tokens for any Authentication grant type.

## Supported ColdFusion Versions
This library aims to support the following CFML
implementations:

* ColdFusion 9, 10
* Railo 3,4

## License

[MIT](http://choosealicense.com/licenses/mit/)
