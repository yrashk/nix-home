{ lib }:

with builtins;
{
  queries = concatStringsSep " " (lib.mapAttrsToList (name: query:  
      ''
      (:name "${name}" :query "${query}")
      '') (import mail/queries));
}
