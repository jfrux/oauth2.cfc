<!--- Client --->
<cfcomponent displayname="oAuth2 Client" output="no" hint="ColdFusion Component for oAuth2 Client" namespace="oAuth2.client" extends="oAuth2.base">
  
  <cfparam name="instance" default="#structnew()#">

  <cffunction name="initialize" hint="Creates a oAuth2 client" returntype="component" output="no">
    <cfargument name="app_id"     type="string" required="true" hint="Application ID">
    <cfargument name="app_secret" type="string" required="true" hint="Application Secret">
    <cfargument name="site_uri"   type="string" required="false" hint="Site URI" default="">
    <cfargument name="options"    type="struct" required="false" hint="Optional configuration options" default="#structnew()#">
      
    <cfset instance.app_id      = arguments.app_id>
    <cfset instance.app_secret  = arguments.app_secret>
    <cfset instance.site_uri    = rereplace(arguments.site_uri, '/$', '')>
    <cfset instance.options     = arguments.options>

    <cfreturn this>
  </cffunction>
  
  <cffunction name="make_request" returntype="struct" roles="" access="public" hint="Makes a request">
    <cfargument name="action" type="string" required="yes" hint="what to request for? get, put, post, delete" />
    <cfargument name="url" type="string" required="yes" hint="where to request" />
    <cfargument name="params" type="struct" required="no" hint="extra params" default="#structnew()#" />
    <cfset var local = {}>
    <cfset local.result = send_request(argumentcollection=arguments)>
    <cfreturn local.result>
  </cffunction>
  
  <cffunction name="send_request" hint="Makes the http request" access="public" returntype="struct">
    <cfargument name="action" type="string" required="yes" hint="what to request for? get, put, post, delete" />
    <cfargument name="url" type="string" required="yes" hint="where to request" />
    <cfargument name="params" type="struct" required="no" hint="extra params" default="#structnew()#" />
    <cfset var local = {}>
    <cfif arguments.action eq 'get'>
      <cfset local.url = build_url(arguments.url, arguments.params)>
      <cftry>
        <cfhttp url="#local.url#" method="#arguments.action#" throwOnError="yes" timeout="60" charset="utf-8"></cfhttp>
        <cfset local.result = deserializejson(cfhttp.filecontent)>
      <cfcatch type="any">
        <cfset local.result = deserializejson(cfhttp.filecontent)>
      </cfcatch>
      </cftry>
    </cfif>
    <cfreturn local.result>
  </cffunction>
  
  <cffunction name="authorize_url" hint="Authorisation URL" access="private" returntype="string">
    <cfargument name="params" type="struct" required="false" hint="Optional params" default="#structnew()#">
    <cfset var local = {}>
    <cfset local.path = "/oauth/authorize">
    <cfif structkeyexists(instance.options, 'authorize_url')>
      <cfset local.path = instance.options.authorize_url>
    </cfif>
    <cfreturn build_url(local.path, arguments.params)>
  </cffunction>

  <cffunction name="access_token_url" hint="Access Token URL" access="private" returntype="string">
    <cfargument name="params" type="struct" required="false" hint="Optional params" default="#structnew()#">
    <cfset var local = {}>
    <cfset local.path = "/oauth/access_token">
    <cfif structkeyexists(instance.options, 'access_token_url')>
      <cfset local.path = instance.options.authorize_url>
    </cfif>
    <cfreturn build_url(local.path, arguments.params)>
  </cffunction>

  <cffunction name="build_url" hint="Builds url" access="private" returntype="string">
    <cfargument name="path" type="string" required="yes" hint="Path">
    <cfargument name="params" type="struct" required="no" hint="Optional parameters" default="#structnew()#">
    <cfset var local = {}>
    <cfset local.query = []>
    <cfloop collection="#arguments.params#" item="key">
      <cfset arrayappend(local.query, (key & "=" & arguments.params[key] & "&"))>
    </cfloop>
    <cfset local.query = arraytolist(local.query, "&")>
    <cfset local.query = rereplace(local.query, '&$', '')>
    <cfset local.url = instance.site_uri & arguments.path & "?" & local.query>
    <cfreturn local.url>
  </cffunction>

</cfcomponent>