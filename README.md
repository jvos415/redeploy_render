# Redeploy on Render

I created this repo and script in order to automate the process of recreating a free postgres instance and update the database urls for my services every month.

Of course this repo will only work if you are using a Render postgres instance and have Render services linked to that DB.

This script can run individual actions or all the actions back-to-back in order to fully redeploy Render services with the new postgres instance db url.

Using this script you can delete an old postgres instance, create a new postgres instance, verify that a postgres instance is ready (i.e. status is available) and then update the the database urls for all services or specific set of services that you specify in your `.env` file.

There is no code required to use this repo. Simply create a `.env.` file and fill in missing fields (more on this below). Yep, that's it.

Feel free to fork this repo and build on it if you need additional customization.

## How to Use

#### Create a Render API Key

Log into Render --> User menu (top right) --> Account settings --> API Keys --> Create an api key and name it "RENDER_API_KEY" or whatever you want

-   Make sure that `jq` is installed on your system (https://jqlang.org/download/)
-   Pull down repo

-   Update `.env` vars using the `.env.sample` as a guide
-   Make sure you can run the script
    -   When you first pull down this repo, the script will not have the correct permissions to run this shell script
    -   At the root of the dir run: `chmod +x redeploy_on_render.sh`. This will grant execute permissions to the shell script



## Additional links / info

[Render API docs](https://api-docs.render.com/reference/list-postgres)
