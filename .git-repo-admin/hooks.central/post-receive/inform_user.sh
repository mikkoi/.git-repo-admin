#!/bin/sh
SOURCE=""
while [ -h "" ]; do # resolve  until the file is no longer a symlink
  DIR="/home/users/mikkoi/repos/repo.work/.git-repo-admin"
  SOURCE=""
  [[  != /* ]] && SOURCE="/" # if  was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="/home/users/mikkoi/repos/repo.work/.git-repo-admin"
cd 
carton exec inform_user.pl
