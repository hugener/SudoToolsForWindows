$commandLine = $args | Select-Object -Skip 1;
Start-Process -FilePath $args[0] -ArgumentList $commandLine -Verb runAs