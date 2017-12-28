{ lib }:

with builtins;

{
  inbox_query = (import ../mail/queries).inbox;
}
