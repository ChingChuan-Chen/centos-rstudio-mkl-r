#!/usr/bin/env bash
set -e
docker build -t jamal0230/centos-rstudio-mkl-r:3.4.4 .
docker push jamal0230/centos-rstudio-mkl-r:3.4.4
docker tag jamal0230/centos-rstudio-mkl-r:3.4.4 jamal0230/centos-rstudio-mkl-r:latest
docker push jamal0230/centos-rstudio-mkl-r:latest

