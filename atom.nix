  {
    "*" = {
       core = {
          telemetryConsent = "limited";
       };
       editor = {
          fontFamily = "Iosevka";
       };
       "exception-reporting" = builtins.replaceStrings ["\n"] [""] (builtins.readFile ./private/atom-exception-reporting);
    };
  }
