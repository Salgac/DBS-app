#!/bin/bash

#script for use on server to launch the app with production environent, bound to port 3000 on ip adress
#!!WORK IN PROGRESS

rails db:migrate
screen rails server --binding=139.162.130.177 -e production