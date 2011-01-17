<!--- Access Token --->
<cfcomponent displayname="oAuth2 Access Token" output="no" hint="ColdFusion Component for oAuth2 Access Token" namespace="oAuth2.AccessToken" extends="oAuth2.base">
  
  <cfparam name="instance" default="#structnew()#">
  
  <cffunction name="initialize" hint="Creates a oAuth2 Access Token" returntype="component">
    <cfargument name="client"         type="component"  required="yes"  hint="The oAuth2 Client to use for this token">
    <cfargument name="token"          type="string"     required="yes"  hint="The token string gained">
    <cfargument name="refresh_token"  type="string"     required="no"   hint="Optional refresh token"           default="">
    <cfargument name="expires_in"     type="numeric"    required="no"   hint="Optional expiry (days)">

    <cfset instance.client        = arguments.client>
    <cfset instance.token         = arguments.token>
    <cfset instance.refresh_token = arguments.refresh_token>
    <cfif structkeyexists(arguments, 'expires_in') and arguments.expires_in neq "">
      <cfset instance.expires_in  = val(arguments.expires_in)>
      <cfset instance.expires_at  = DateAdd('d', instance.expires_in, now())>
    </cfif>
    
    <cfreturn this>
  </cffunction>
  
  <cffunction name="expires" hint="Does the token expire?" returntype="bool">
    <cfreturn not structkeyexists(instance, 'expires_in')>
  </cffunction>
  
  <cffunction name="send_request" hint="Wrapper for Access Token calls" returntype="struct">
    <cfargument name="action" type="string" required="yes" hint="what to request for? get, put, post, delete" />
    <cfargument name="url" type="string" required="yes" hint="path to request">
    <cfargument name="params" type="struct" required="no" hint="extra params" default="#structnew()#" />
    <cfargument name="headers" type="struct" required="no" hint="extra headers" default="#structnew()#" />
    <cfset var local = {}>
    <cfset arguments.params['access_token'] = instance.token>
    <cfset arguments.headers['Authorization'] = 'Token token = "' & instance.token & '"' >
    <cfset local.result = instance.client.make_request(argumentcollection=arguments)>
    <cfreturn local.result>
  </cffunction>
  
  <cffunction name="get" hint="get" returntype="struct">
    <cfargument name="url" type="string" required="yes" hint="path to request">
    <cfargument name="params" type="struct" required="no" hint="extra params" default="#structnew()#" />
    <cfargument name="headers" type="struct" required="no" hint="extra headers" default="#structnew()#" />
    <cfset arguments['action'] = 'get'>
    <cfreturn send_request(argumentcollection=arguments)>
  </cffunction>
  
  <cffunction name="post" hint="post" returntype="struct">
    <cfargument name="url" type="string" required="yes" hint="path to request">
    <cfargument name="params" type="struct" required="no" hint="extra params" default="#structnew()#" />
    <cfargument name="headers" type="struct" required="no" hint="extra headers" default="#structnew()#" />
    <cfset arguments['action'] = 'post'>
    <cfreturn send_request(argumentcollection=arguments)>
  </cffunction>
  
  <cffunction name="put" hint="put" returntype="struct">
    <cfargument name="url" type="string" required="yes" hint="path to request">
    <cfargument name="params" type="struct" required="no" hint="extra params" default="#structnew()#" />
    <cfargument name="headers" type="struct" required="no" hint="extra headers" default="#structnew()#" />
    <cfset arguments['action'] = 'put'>
    <cfreturn send_request(argumentcollection=arguments)>
  </cffunction>
  
  <cffunction name="delete" hint="delete" returntype="struct">
    <cfargument name="url" type="string" required="yes" hint="path to request">
    <cfargument name="params" type="struct" required="no" hint="extra params" default="#structnew()#" />
    <cfargument name="headers" type="struct" required="no" hint="extra headers" default="#structnew()#" />
    <cfset arguments['action'] = 'delete'>
    <cfreturn send_request(argumentcollection=arguments)>
  </cffunction>
  
</cfcomponent>