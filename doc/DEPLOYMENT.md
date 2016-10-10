# Deployment information

This document gives all the necessary information in order to deploy reminisce.me on a remote machine.

## Prerequisites

1. Install [docker](https://docs.docker.com/engine/getstarted/step_one/) (on both the local machine and the remote machine).
2. Install [docker-compose](https://docs.docker.com/compose/install/)
3. Install [docker-machine](https://docs.docker.com/machine/install-machine/)
4. Setup a remote in docker-machine:

    ```bash
    $ docker-machine create \
      --driver generic \
      --generic-ip-address=<remote_ip> \
      --generic-ssh-key \
      ~/.ssh/id_rsa \
      reminisce.me
    ```
    Note that you can omit the ssh key if the key is handled by `ssh-agent`. The driver can be a different one if you are using a remote hosted on one of the hosting providers supported by docker-machine (see  [drivers documentation](https://docs.docker.com/machine/drivers/) dor more information)

## Building the images

You may want to rebuild the images to apply your changes. For this you simply have to do the following:

1. Clone the three repositories ([app](https://github.com/reminisceme/app), [game-creator](https://github.com/reminisceme/game-creator) and [reverse-geoloc](https://github.com/reminisceme/reverse-geoloc)).
2. For each image you want to build, do the following:

    ```bash
    $ cd $REPO
    $ docker build . -t reminisceme/$REPO:$VERSION
    $ docker tag reminisceme/$REPO:$VERSION reminisceme/$REPO:latest
    $ docker login #login to your DockerHub account
    $ docker push reminisceme/$REPO:$VERSION
    $ docker push reminisceme/$REPO:latest
    ```

The server will then be able download the images directly from the DockerHub.

## Nginx and SSL

### SSL setup
Currently we are using a Let's Encrypt certificate for SSL. In order for this to work, you need to generate a key using the Let's Encrypt tools (see the documentation for [certbot](https://certbot.eff.org/), it is easier to generate the certificate using the standalone mode the first time). The files need to be placed under `/etc/letsencrypt/live/reminisce.me/` on the remote (default location). On top of that we require that a set of Diffie-Hellman parameters are provided to the nginx proxy:

```bash
$ openssl dhparam -out dhparam.pem $KEY_SIZE
```
This file should then be placed in `/etc/ssl/dhparams/dhparam.pem` on the remote server.

You can edit those locations by editing `nginx/nginx.conf` and `docker-compose.yml` in this repository but be careful: you might need to edit some of the scripts as they rely on those locations.

### SSL renewal

The nginx image is build with an automatic renewal script. As advised in the certbot documentation, this script can be setup to be run twice a day by a cron job on the remote once the containers are built and running:

```bash
$ docker exec deployment_nginx_1 /renew_certificate.sh
```

Note that the container name (`deployment_nginx_1`) is the one generate by docker-compose, under a different setup, this name may vary.

## Environment

A file, located in `env/prod.sh` on the local machine (relative to the `docker-compose.yml` file location), should be provided with the following information in it:

```
MONGO_URL=mongodb://mongo/reminisceme
ROOT_URL=http://your.url.com
DISABLE_WEBSOCKETS=1
PORT=3000
GAME_CREATOR_URL=http://game-creator:9900
TIMEOUT_BETWEEN_FETCHES=5000
FACEBOOK_APPID=...
FACEBOOK_SECRET=...
GMAPS_KEY=...
```

## Deployment per se

### First deployment
Once everything is setup. You can run the following to deploy the application:

```bash
$ eval $(docker-machine env reminisce.me)
# From that point on, all your docker and docker-machine commands will be run on the remote
# if you want to end this, simply run "eval $(docker-machine env --unset)"
$ docker-compose up -d
```
This will build anything that needs to be built, pull anything that needs to be pulled and start the containers. Note that the first time the project is ran, the indexation of the reverse geolocation data might take a lot of time (35 to 50 minutes).

If you want to see the standard output of one (or more) of the services:

```bash
$ docker-compose logs -f $service1 $service2 ...
```
If you do not provide any service name, it will show you all the logs.

### Next deployments

For any service except the nginx service, proceed as follows:

1. Make sure your image is built and tagged as latest on the DockerHub
2. Put the website in maintenance mode:

    ```bash
    $ docker exec deployment_nginx_1 /maintenance_on.sh  
    ```
3. Stop the service:

    ```bash
    $ docker-compose stop $service
    ```
4. Remove the container:

    ```bash
    $ docker-compose rm $service
    ```
5. Remove the image (you can find the hash by running `docker images`) so that it is pulled again:

    ```bash
    $ docker rmi $image_hash
    ```
6. Bring the container back up:

    ```bash
    $ docker-compose up $service
    ```
7. End the maintenance:

    ```
    docker exec deployment_nginx_1 /maintenance_off.sh
    ```

If you need to rebuild the nginx container, there is no use entering maintenance mode so just proceed with the stop/remove/rebuild steps (3. to 6.).
