component extends="oauth2.strategy.base" {
  public function getAuthorize_url() {
    throw(type="oAuth2.not_implemented",message="The authorization endpoint is not used in this strategy.");
  }
  public function get_token(username,password,params={},opts={}) {
    var oAuth2Client = getClient();
    var reqParams={
      'grant_type': 'password',
      'username': arguments.username,
      'password': arguments.password
    }

    structAppend(reqParams,client_params());

    oAuth2Client.get_token(params=reqParams,access_token_opts=arguments.opts);
  }
}
