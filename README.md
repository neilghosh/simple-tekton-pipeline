Allocate CPUs to your cluster 

``` gcloud container clusters resize knative-demo --num-nodes=4 --zone=us-central1-c ```

Get the kubernetes context to get kubectl working.

``` gcloud container clusters get-credentials knative-demo --zone us-central1-c --project demoneil ```

Get the nodes of the cluster to make sure there are enough 

```kubectl get nodes```

Check serving components 

``` kubectl get pods --namespace knative-serving```

Deploy a version 

``` ubectl apply --filename service.yaml ```

Check service 

``` kubectl get ksvc helloworld-go ```

Install Tekton pipeline 

```
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

kubectl get pods --namespace tekton-pipelines --watch
```

Creating & Running Tasks 
https://github.com/tektoncd/pipeline/blob/master/docs/tutorial.md
tkn  taskrun  list
tkn tr logs echo-hello-world-task-run-hcwhw

Create a Task RUN (For auto generating names user create instead of apply )

`kubectl create -f build_TaskRun.yaml`

Check Status of run

`tkn taskrun describe build-image-9m8qt`

Deploy
https://developer.ibm.com/tutorials/knative-build-app-development-with-tekton/

```
kubectl apply -f pipeline/deploy_Pipeline.yaml
sh access/assignRoles.sh
kubectl apply -f deploy/clusterrole.yaml
kubectl create -f pipeline/deploy_PipelineRun.yaml
tkn  pipelinerun list
pipelinerun logs tutorial-pipeline-run-<AUTO_GENERATED_SUFFIX>
kubectl get deployments
```

Deploy as knative service

```
kubectl apply -f knative/clusterrole.yaml
kubectl apply -f knative/deploy-image-as-knative-service.yaml
kubectl apply -f knative/deploy_pipiline.yaml
kubectl create -f knative/deploy_PipelineRun.yaml


kubectl get ksvc
kubectl get pods
```

Save Cluster Cost
``` gcloud container clusters resize knative-demo --num-nodes=0 --zone=us-central1-c ```



