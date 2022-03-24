# SwaggerJsonExtractor (Powershell)
## Description
This simple script helps you to extract only the paths you want from a swagger json and generates a new swagger json with all schemas used in the selected paths.

## How to use
1. Download the SwaggerJsonExtractor.ps1
2. Open a PowerShell console in the same directory as the script is stored
3. Provide the script with the source swagger json, you want to extract from, in one of the following ways:
    * Pipe the swagger string into the script  
    ```powershell 
    PS> '{"openapi": "3.0.1", "info": {"title": ""}/*[...]*/}' | ./SwaggerJsonExtractor.ps1
    ```
    * Pass the swagger string as a parameter
    ```powershell 
    PS> ./SwaggerJsonExtractor.ps1 -SwaggerJsonString '{"openapi": "3.0.1", "info": {"title": ""}/*[...]*/}'
    ```
    * Copy the swagger string into your Clipboard and run script
    ```powershell 
    PS> ./SwaggerJsonExtractor.ps1
    ```
    * Pass a FilePath to the swagger json file
    ```powershell 
    PS> ./SwaggerJsonExtractor.ps1 -InputPath "C:\temp\swagger.json"
    ```
4. Enter the relative endpoint paths as they are shown in swagger doc
    ```powershell 
    PS> PathsToExtract[0]: /api/user/{id}
    PS> PathsToExtract[1]: /api/group/{id}
    ```
    You can also pass an array directly as a parameter when calling the script
    ```powershell 
    PS> ./SwaggerJsonExtractor.ps1 -PathsToExtract @("/api/user/{id}", "/api/group/{id}")
    ```
5. The script outputs the new json to the console and pastes the json to your clipboard.  
       You can specify a outputfile with the property `-OutputPath` to have the result stored to a file  
       You can suppress the console output and the clipboard paste by using the `-SuppressConsoleOutput` and `-SuppressClipboardOutput`
