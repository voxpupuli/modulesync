#!/bin/sh

commit_msg_path=$1/.git/hooks/commit-msg

if [ ! -f $commit_msg_path ]; then
  curl -s -Lo $commit_msg_path http://review.openstack.org/tools/hooks/commit-msg
  chmod 775 $commit_msg_path
fi
