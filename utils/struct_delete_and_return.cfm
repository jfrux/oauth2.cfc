<cfscript>
private any function structDeleteAndReturn(struct theStruct,string theKey) {
  var returnVar = false;
  if (structKeyExists(arguments.theStruct,arguments.theKey)) {
    returnVar = arguments.theStruct[arguments.theKey];

    structDelete(arguments.theStruct,arguments.theKey);
    return returnVar;
  }

}
</cfscript>
