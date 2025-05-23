# Redeploy on Render

-   I created this repo in order to automate the process of recreating a free postgres instance and then having to update the database urls for my services every month.
-   Of course this repo will only work if you are using a Render postgres instance and have Render services set up to use that same postgres instance. You should, in the least, have your services set up and working prior to using this script.
-   This script can run individual actions or all the actions back-to-back in order to fully redeploy Render services with the new postgres instance db url.
-   This script allows you to delete an old postgres instance, create a new postgres instance, verify that a postgres instance is ready (i.e. status is available) and update the database urls for all services or a specific set of services that you specify in your `.env` file.
-   There is no coding required to use this repo. Simply create a `.env.` file, fill in missing fields (more on this below) and run it. Yep, that's it.
-   Fork this repo and build on it if you need additional customization.

# Script Set Up

#### Create A Render API Key

-   Sign In to Render --> User menu (top right) --> Account settings --> API Keys --> Create an api key and name it "RENDER_API_KEY" or whatever you want

#### Make Sure jq Is Installed

-   Make sure that `jq` is installed on your system. (https://jqlang.org/download/)

#### Pull Down Repo and Create .env File

-   Pull down repo so you can update the env vars and run locally
-   Open the repo using your favorite IDE
-   Update `.env` vars by copying the `.env.sample` and using it as a guide
-   Grant execute permissions to run this script
    -   When you first pull down this repo, you will not have the correct permissions to run this shell script
    -   At the root of the dir run: `chmod +x redeploy_render.sh`. This will grant execute permissions to the shell script

# Script Usage

-   To use this script you can run `./redeploy_render.sh` or `bash redeploy_render.sh` at the root of this repo
-   This will bring up the usage details as we have not passed an arg to the script
-   Possible arg options (and sample usages):

    -   `./redeploy_render.sh -delete_db` - Deletes current postgres instance
    -   `./redeploy_render.sh -create_db` - Creates a new postgres instance
    -   `./redeploy_render.sh -verify_ready` - Verifies that the current postgres instance is ready (available)
    -   `./redeploy_render.sh -update_db_urls` - Updates all internal db urls for services from env var RENDER_SERVICES_IDS or, if RENDER_SERVICES_IDS is commented out, then automatically update internal db urls for all services
    -   `./redeploy_render.sh -redeploy` - Runs all actions in a row (This will likely be the most common usage)
    -   `./redeploy_render.sh -h` or `./redeploy_render.sh --help` - Brings up the usage menu

-   Optionally, you can pass multiple arguments at once but please note that they should be passed in order, otherwise there will be unexpected behavior
-   For example: You may want to delete your current DB instance and create a new one without completing the remaining steps. To do this, you would run the script with two args, like this: `./redeploy_render.sh -delete_db -create_db`

## Additional Link / Info

[Render API docs](https://api-docs.render.com/reference/list-postgres)
