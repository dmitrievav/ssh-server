#!/bin/bash
docker build -t dmitrievav/ssh-server -f Dockerfile .
docker push dmitrievav/ssh-server

