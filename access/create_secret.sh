#build-app-q49wb
kubectl create secret docker-registry gcr-json-key \
 --docker-server=gcr.io \
 --docker-username=_json_key \
 --docker-password="$(cat ~/gcr.json)" \
 --docker-email=neil.ghosh@gmail.com