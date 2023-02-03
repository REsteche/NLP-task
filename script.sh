#!/bin/bash

set -x
flags="--debug --pretty --skip-questions"

# define a model
nha ${flags} model new \
--name fly-clf-ruben \
--desc "Intent classifier for travel information queries" \
--model-file '{"name": "clf.pkl", "required": true, "desc": "Classifier saved as pickle", "max_mb": 1}' \
--data-file '{"name": "atlas_intents.csv"}' 
# check it at nha model list, or specify with nha model list | grep ruben

# record a dataset
nha ${flags} ds new \
--name fly-data-v0 \
--model fly-clf-ruben \
--details '{"extraction_date": "2023-02-02"}' \
--path ./datasets/
# check it at nha ds list

# create your project
nha ${flags} proj new \
--name airplanes \
--desc "A model to classify airline related queries intentions" \
--home-dir '.' \
--model fly-clf-ruben
# check it at nha proj list

# build your project # now it's "dockerized" :)
nha ${flags} proj build \
--from-here
# you can check it here using $ docker images or specify with docker images | grep  flowers  

# note that a docker image has been created for you
docker images noronha/*airplanes*

# and it's also versioned in noronha's database
nha ${flags} bvers list
# nha bvers list will work out too

# Run a Jupyter Notebook for editing and testing your code:
nha ${flags} note --port 30091 --edit --dataset fly-clf-ruben:fly-data-v0

# execute your first training 
nha ${flags} train new \
--name experiment-v1 \
--nb notebooks/train \
--params '{"gamma": 0.001, "kernel": "linear"}' \
--dataset fly-clf-ruben:fly-data-v0

# check out which model versions have been produced so far
nha ${flags} movers list

# deploy a model version to homologation
nha ${flags} depl new \
--name homolog \
--nb notebooks/predict \
--port 30050 \
--movers fly-clf-ruben:experiment-v1 \
--n-tasks 1 \
&& sleep 10

# test your api (direct call to the service)
curl -X POST \
--data 'all flights from baltimore after 6 pm' \
http://127.0.0.1:30050/predict \
&& echo

# test your api (call through model router)
curl -X POST \
-H 'Content-Type: application/JSON' \
--data 'all flights from baltimore after 6 pm' \
"http://127.0.0.1:30080/predict?project=flowers&deploy=homolog" \
&& echo
