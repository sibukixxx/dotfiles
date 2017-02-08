## (Docker-Machine)

# docker-machine
if [ "`docker-machine status dev`" = "Running" ]; then
   eval "$(docker-machine env dev)"
fi
#eval "$(docker-machine env digitalocean-docker)"
