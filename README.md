# ado-automate-sample
Sample for automating the creation of a branch, commit and PR for Azure DevOps using a logic app.  This was created in order to trigger and ESLZ landing zone subscription creation.

To run, publish the logic app or run in the VS Code debugger.
The logic app is triggered from an HTTP Post, there is a sample input document called input.json that can be used.  Please edit values before sending.
When running in the debugger, use the REST Client VS Code extension and send the request contained in the tests.http file.  After the extension is installed a 'Send Request' link appears above the POST request. 

The URL in tests.http will need to be edited.  To get it, start the debugger, then click Overview on the workflow.json file.  The full URL is displayed there, it is different to the one displayed in the functions output window.

This is a work-in-progress, I would like to address the following issues:
1. The Pull Request is hard wired to pull from the created branch into main.  The target branch should be configurable.
2. This sample only works with Azure DevOps Repos, it would be good to do a GitHub version.
3. There is no custom error handling, just the default error message is returned.
4. There is no upsert functionality, a new branch and file is created each time, if the branch exists the process fails, we should check for existence and update.
5. There is no CICD pipeline functionality
