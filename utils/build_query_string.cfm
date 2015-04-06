<cfscript>
/**
* @hint I return a string containing any extra URL parameters to concatenate and pass through when authenticating.
* @description I return a string containing any extra URL parameters to concatenate and pass through when authenticating.
* @argScope A structure containing key / value pairs of data to be included in the URL string.
**/
public string function buildParamString( struct params={} ) {
  var strURLParam = '';
  if(structCount(arguments.params)) {
    for (key in arguments.params) {
      if(listLen(strURLParam,'&') GT 0) {
        strURLParam = strURLParam & '&';
      }
      strURLParam = strURLParam & lcase(key) & '=' & trim(arguments.params[key]);
    }
    // strURLParam = '&' & strURLParam;
  }
  return strURLParam;
}
</cfscript>
