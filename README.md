# ado-automate-sample
Sample for automating the creation of a branch, commit and PR for Azure DevOps using a logic app.  This was created in order to trigger and ESLZ landing zone subscription creation.

To run, set up an ADO pipeline using /pipelines/ado/core-pipelines.yaml or run in the VS Code debugger.
The logic app is triggered from an HTTP Post, there is a sample input document called input.json that can be used.  Please edit values before sending.
When running in the debugger, use the REST Client VS Code extension and send the request contained in the tests.http file.  After the extension is installed a 'Send Request' link appears above the POST request. 

The URL in tests.http will need to be edited.  To get it, start the debugger, then click Overview on the workflow.json file.  The full URL is displayed there, it is different to the one displayed in the functions output window.

GitHub functionality is being added, this requires a keyvault to hold the PAT token.  To deploy this do the following:
1. Run this command to get the current user object id: az ad user show --id <your email> --query id
2. Add the object id to the /bicep/keyvault.parameters.json file
3. Swith to the bicep folder
4. Run az deployment group create --name kvdeploy -g <your resource group> --template-file keyvault.bicep --parameters @keyvault.parameters.json
5. Generate a PAT token in GitHub, use classic, fine grained doesn't work
6. In Keyvault update the GitHubPATSecret with the new PAT token

The logic app connection can expire in VS code if left for too long.  There is a key required that initially gets added to the local.settings.json file.  The DevOps connection can be recreated by running the apiconnections.bicep file and saving the output key value in the above file.

This is a work-in-progress, I would like to address the following issues:
1. The Pull Request is hard wired to pull from the created branch into main.  The target branch should be configurable.
2. There is no custom error handling, just the default error message is returned.
3. There is no upsert functionality, a new branch and file is created each time, if the branch exists the process fails, we should check for existence and update.

The following manual actions need to be done:
* For local debugging rename local.settings.json.new to local.settings.json
* Update the placeholder values within it.
* Update the visualstudioteamservices-connectionKey setting by running the apiconnections.bicep
* The deployed API connection needs to be authorised in the Azure portal, go to Edit API connection
* The connection runtime URL needs to be set in app settings and the local.settings.json file.  This is available in the properties of the API connection 

