#!/usr/bin/env bash
PATH="$PATH:/usr/local/bin"
MACHINE="$1"
MACHINES=$(docker-machine ls -q | grep "$MACHINE")
MACHINE_STATUS=$(docker-machine status "$MACHINE" 2> /dev/null)
VALID_MACHINE=$?
echo "<?xml version='1.0'?><items>"
if [ "$VALID_MACHINE" = "0" ]
then
  if [ "$MACHINE_STATUS" = "Running" ]
  then
    echo "<item arg=\"machine stop '$MACHINE'\" uid=\"$MACHINE\">"
    echo "  <title>Shut Down Machine $MACHINE</title>"
    echo "  <subtitle>Will shut down all containers on $MACHINE</subtitle>"
    echo "</item>"
    ENV=$(docker-machine env --shell sh "$MACHINE")
    eval "$ENV"
    CONTAINERS="$(docker ps --format "{{.Names}} ({{.Image}})|Running for: {{.RunningFor}}|{{.ID}}")"
    if [ "$CONTAINERS" != "" ]
    then
      while read -r CONTAINER
      do
        CONTAINER_ID=$(echo "$CONTAINER" | sed 's/.*|//')
        CONTAINER_NAME=$(echo "$CONTAINER" | sed 's/|.*//')
        CONTAINER_SUBTITLE=$(echo "$CONTAINER" | sed 's/.*|\(.*\)|.*/\1/')
        echo "<item arg=\"container stop '$MACHINE' '$CONTAINER_ID'\">"
        echo "  <title>Shut down $CONTAINER_NAME</title>"
        echo "  <subtitle>$CONTAINER_SUBTITLE</subtitle>"
        echo "</item>"
      done <<< "$CONTAINERS"
    fi
  else
    echo "<item arg=\"machine start '$MACHINE'\" uid=\"$MACHINE\">"
    echo "  <title>Boot Docker Machine $MACHINE</title>"
    echo "</item>"
  fi
else
  while read -r MACHINE
  do
    MACHINE_VERSION=$(docker-machine version $MACHINE)
    MACHINE_STATUS=$(docker-machine status $MACHINE)
    MACHINE_DRIVER=$(docker-machine inspect $MACHINE | sed -n 's/.*"DriverName": "\(.*\)",/\1/p')
    echo "<item arg=\"$MACHINE\" uid=\"$MACHINE\" valid=\"no\" autocomplete=\"$MACHINE\">"
    echo "  <title>$MACHINE</title>"
    echo "  <subtitle>$MACHINE_STATUS (Docker $MACHINE_VERSION on $MACHINE_DRIVER)</subtitle>"
    echo "</item>"
  done <<< "$MACHINES"
fi
echo "</items>"
