component extends="oauth2.strategy.base" {
  public function authorize_params(params = {}) {
    structAppend(arguments.params,{ 'response_type': 'code', 'client_id': getClient().getId() });
    return arguments.params;
  }
  public function getAuthorize_url() {
    var oAuth2Client = getClient();
    var reqParams = {}

    structAppend(reqParams,arguments.params,true);

    return oAuth2Client.getAuthorize_url(reqParams);
  }

  public function get_token(code,params={},opts={}) {
    var oAuth2Client = getClient();
    var reqParams={
      'grant_type': 'authorization_code',
      'code': arguments.code
    }

    structAppend(reqParams,client_params(),true);

    oAuth2Client.get_token(params=reqParams,access_token_opts=arguments.opts);
  }
}
