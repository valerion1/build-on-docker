#!/bin/bash


SCRIPT_PATH="`dirname \"$0\"`"              # relative
SCRIPT_PATH="`( cd \"$SCRIPT_PATH\" && pwd )`"  # absolutized and normalized

if [ -z "$SCRIPT_PATH" ] ; then
  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  exit 1  # fail
fi


if [ -f "$SCRIPT_PATH/../.env" ] ;
	then
		rm "$SCRIPT_PATH/../.env"
fi

cp "$SCRIPT_PATH/.env.dev" "$SCRIPT_PATH/../.env"

cd "$SCRIPT_PATH/docker" && \
	docker-compose up -d --build


docker exec app-container mkdir -p storage/framework/sessions
docker exec app-container mkdir -p storage/framework/views
docker exec app-container mkdir -p storage/framework/cache
docker exec app-container chmod 777 -R storage/

docker run --rm --interactive --tty \
    --volume "$SCRIPT_PATH/../":/app \
    composer install

docker exec app-container php artisan config:clear
docker exec app-container php artisan key:generate
sleep 2 # "connection refused" without sleep
docker exec app-container php artisan migrate