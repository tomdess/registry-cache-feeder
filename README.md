# ACR Harbor local cache feeder (triggered by webhook)

I use Azure Container Registry as main container registry and an instance of [Harbor](https://goharbor.io/) as a local registry cache.

I want that as soon as a new image is pushed to ACR the image is immediately available even in local Harbor cache without waiting for fixed schedule timing.

To accomplish this i create a docker container to handle push events configured in a Webhook defined in ACR and for each event start a local image pull on local cache to trigger the download of new image.

The docker image is basically an alpine + [`webhook`](https://github.com/adnanh/webhook)  + [`skopeo`](https://github.com/containers/skopeo).

Derived from image mainteined by [`TheCatLady`](https://github.com/TheCatLady/docker-webhook) i add an `app` user to avoid running webhook as root.

---

## Configuration

### ACR hook configuration

Create a Webhook on own ACR registry, with azure cli run the following command:

 ```
 ✗ az acr webhook create \
  --name DemoHook \
  --registry myRegistry \
  --uri https://registry-cache-feeder.example.com/hooks/acr-push-event \
  --actions push \
  --headers "X-Static-Token=mySecretTokenHash"
  
```
Use an https endpoint, the authorization mechanism is quite weak cause is based on a static token, so use at least https to protect.
As a best practice the docker container should be contacted via a reverse proxy, not exposed directly on public net (i.e. see my [`docker-haproxy-certbot`](https://github.com/tomdess/docker-haproxy-certbot) project)


### Docker compose configuration

The compose file read a local .env file to get specific values, copy DOT.env.template in .env and set your values for followinf vareiables:

```
- HARBOR_URL # harbor hostname and project (i.e. myharbor.mynet/acr-cache)
- ACRTOKEN # value of X-Static-Token header defined in ACR hook
- SRC_TLS # use TLS to connect to harbor registry [true/false]
- SCRIPT_DEBUG # script in verbose mode [true/false]
```
The webhook configuration is in `config/hooks.json` file. See [`adnanh/webhook`](https://github.com/adnanh/webhook) for documentation on how to define hooks.

## Usage

Start the container (and build):

`docker compose up -d --build`

Stop the container:

`docker compose down`

Check logs:

`docker compose logs -f`

```
harborcachefeeder  | [webhook] 2025/04/30 17:56:46 version 2.8.1 starting
harborcachefeeder  | [webhook] 2025/04/30 17:56:46 setting up os signal watcher
harborcachefeeder  | [webhook] 2025/04/30 17:56:46 attempting to load hooks from hooks.json
harborcachefeeder  | [webhook] 2025/04/30 17:56:46 os signal watcher ready
harborcachefeeder  | [webhook] 2025/04/30 17:56:46 found 1 hook(s) in file
harborcachefeeder  | [webhook] 2025/04/30 17:56:46 	loaded: acr-push-event
harborcachefeeder  | [webhook] 2025/04/30 17:56:46 serving hooks on http://0.0.0.0:9000/hooks/{id}
harborcachefeeder  | [webhook] 2025/04/30 18:02:49 [41ba80] incoming HTTP POST request from 192.168.1.120:38172
harborcachefeeder  | [webhook] 2025/04/30 18:02:49 [41ba80] acr-push-event got matched
harborcachefeeder  | [webhook] 2025/04/30 18:02:49 [41ba80] acr-push-event hook triggered successfully
harborcachefeeder  | [webhook] 2025/04/30 18:02:49 [41ba80] 200 | 0 B | 313.342µs | webhook.example.com | POST /hooks/acr-push-event
harborcachefeeder  | [webhook] 2025/04/30 18:02:49 [41ba80] executing /config/script-acr.sh (/config/script-acr.sh) with arguments ["/config/script-acr.sh"] and environment [ACTION=push REPO=lab/cmter TAG=8.28 DIGEST=sha256:290d775128c84ad45d4b3158c0abd7b1244a8214d77c376b6ae959017cbd2b40] using /config as cwd
harborcachefeeder  | [webhook] 2025/04/30 18:02:51 [41ba80] command output: Pulling the image to feed the cache...........
harborcachefeeder  | Getting image source signatures
harborcachefeeder  | Copying blob sha256:03d8fc5502c72eb0e8e68ffcefdac79ffc265ed6afba5afdbbc56a23834e6f95
harborcachefeeder  | Copying blob sha256:205430665e70210b1292f0a4925be96862bbc5c6181e4d6052ae8b9bf6d103f4
harborcachefeeder  | Copying blob sha256:9433b749884eef2448393de076f8750bafb87a65c0fd21fd48a899a4b3a990d5
harborcachefeeder  | Copying config sha256:4fd6de627916551e6469e8308329765d345df42d9a2793bae40cbc612d6dbb6a
harborcachefeeder  | Writing manifest to image destination
harborcachefeeder  | Elapsed time : 0 days 00 hr 00 min 02 sec
harborcachefeeder  | 
harborcachefeeder  | [webhook] 2025/04/30 18:02:51 [41ba80] finished handling acr-push-event

```
 

## Credits

thanks to:

[`webhook`](https://github.com/adnanh/webhook) project

[`TheCatLady`](https://github.com/TheCatLady/docker-webhook) docker image of webhook

[`skopeo`](https://github.com/containers/skopeo) project used to pull images inside the container
