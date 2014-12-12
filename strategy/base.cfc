component accessors="true" {
  /**
  * @getter true
  * @setter true
  * @type oauth2.client
  * @hint The client for your strategy
  **/
  property name="client";

  public oauth2.strategy.base function init(oauth2.client client) {
    setClient(arguments.client);

    return this;
  }

  public function client_params() {
    return {
      'client_id': getClient().getId(),
      'client_secret': getClient().getSecret()
    }
  }
}
