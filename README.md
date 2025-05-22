# Redeploy on Render

This repo will contain a script that allows you to quickly redeploy your free render instance.

#### Create a Render API Key

User menu --> Account settings --> API Keys --> Create an api key and name it "RENDER_REDEPLOY_KEY" or whatever you want

Render API docs link for reference
https://api-docs.render.com/reference/list-postgres

#### How to use

 - Make sure that `jq` is installed on your system (https://jqlang.org/download/)
 - Pull down repo
 - 
 - Update `.env` vars using the `.env.sample` as a guide
 - Make sure you can run the script
    * When you first pull down this repo, the script will not have the correct permissions to run this shell script
    * At the root of the dir run: `chmod +x redeploy_on_render.sh`. This will grant execute permissions to the shell script

