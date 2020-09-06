kubectl create clusterrolebinding tutorial-binding \
             --clusterrole=tutorial-role \
             --serviceaccount=default:tutorial-service