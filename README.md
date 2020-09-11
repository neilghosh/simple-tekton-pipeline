# Deploy Knative and Kubernetes Apps using Tekton Pipelines

This repo contains artifacts and commands to get started with tekton. The goal is to demonstrate and end-to-end use case of tekton where continuous integration (CI) can be done to build a docker image with a golang app code sitting in git (same repository here) and push to Google Container Registry (GCR). Further the same image is used in continuos deployment (CD) to deploy to a Kubernetes cluster (GKE in this case) both as a Knative service (Knative servicing components installation is prerequisite) and a Kubernetes deployment ( separate load balancer may be additionally required to access it).


Since Kubernetes cluster infrastructure is costly I like to keep it scaled down to zero to save cost. I also make sure its a [zonal cluster](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters) so that it does not charge for the "Cluster Management Fee" as I keep the cluster running even without nodes.

So before doing anything else... 

## General Setup

Allocate CPUs to your cluster. 

`gcloud container clusters resize knative-demo --num-nodes=4 --zone=us-central1-c `

Get the kubernetes context to get kubectl working.

`gcloud container clusters get-credentials knative-demo --zone us-central1-c --project demoneil `

Get the nodes of the cluster to make sure there are enough compute.

`kubectl get nodes`

Check knative serving components, this must have been installed already during [knative setup](https://knative.dev/docs/install/any-kubernetes-cluster/). This is needed for deploying knative services. 

`kubectl get pods --namespace knative-serving`

Deploy simple knative app to check knative setup. You can use the sample [manifest file](knative/knative-service.yaml) from this repo after *replacing the image url*

`kubectl apply --filename service.yaml ```

Check if service is deployed and serving url is available. 

`kubectl get ksvc helloworld-go`

## Install Tekton 

```
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

kubectl get pods --namespace tekton-pipelines --watch
```

Creating & Running Tasks 
https://github.com/tektoncd/pipeline/blob/master/docs/tutorial.md

You can create a simple [task](simple/hello-task.yaml) and [taskrun](simple/hello-taskRun.yaml) to check your tekton setup.

## Build

Let's get serious. Create a [task](build/build_task.yaml) to build an image from source repository. This in turn used the [git resource](resources/git_pipelineResource.yaml) and [image resource](resources/image_pipelineResource.yaml). They are kind of source and destination for this build step.

Create a [taskrun](build/build_TaskRun.yaml) to run the task. Note that *for auto generating names user create instead of apply.*

`kubectl create -f build_TaskRun.yaml`

List the taskruns and find the name of the latest taskrun

`tkn  taskrun  list`

See logs of the taskrun if everything is going fine.

`tkn tr logs echo-hello-world-task-run-hcwhw`

Describe to check the status of task run

`tkn taskrun describe build-image-9m8qt`

At the end of the successful taskRun there should be an docker image created at the location mentioned in the image resource.

## Deploy

A reference tutorial 

https://developer.ibm.com/tutorials/knative-build-app-development-with-tekton/

Pipelines are used to stitch various tasks which analogous to Jobs if you are coming from the Jenkins world or stage if you are coming from [Spinnaker](https://spinnaker.io/).

Let's creating a pipeline which stitches the build task and a [deploy task](deploy/deploy_task.yaml).

`kubectl apply -f pipeline/deploy_Pipeline.yaml`

Before we run the pipeline tekton although running in the same cluster would need access to deploy (aka mess with deployment objects) in the cluster. If you had deployed manually applying the deployment manifest file using kubectl, you did not need this because kubectl is already authenticated. Here you are going to use kubectl but only to tell tekton to deploy in turn. So lets set the access up.

* Since this is GKE create a [service account json key](https://cloud.google.com/iam/docs/creating-managing-service-account-keys).
* Create a [Kubernetes secret](access/create_secret.sh) using the above key.
* Create clusterrolebinding `sh access/assignRoles.sh
`.
* Create a clusterrole `kubectl apply -f deploy/clusterrole.yaml`. 

All set. Let's run the pipeline i.e. create a PipelineRun.

`kubectl create -f pipeline/deploy_PipelineRun.yaml`

List down the PipelineRuns
`tkn  pipelinerun list`

Check logs.

`pipelinerun logs tutorial-pipeline-run-<AUTO_GENERATED_SUFFIX>`
`

Once this is successful, you should see your deployment in the cluster.

`kubectl get deployments`

## Deploy as knative service

Now lets deploy the same image as Knative service so that the service URL comes as free and it can be directly consumed using curl or browser.

Let's create the task which deploys a knative service given a [service.yaml](simple/service.yaml) manifest file.

`kubectl apply -f knative/deploy-image-as-knative-service.yaml`

Create a pipeline which stitches our old build task to the new deployment task. The way we build the [go app code](app/helloworld.go) using [docker](app/Dockerfile) does not change so we re-use the earlier build task.

`kubectl apply -f knative/deploy_pipiline.yaml`

Now before we actually deploy the cluster role needs to have different permission to "mess" with knative service objects.

`kubectl apply -f knative/clusterrole.yaml`

let's deploy as Knative service.

`kubectl create -f knative/deploy_PipelineRun.yaml`

Once this is successful. You should be able to see the knative service deployed.

`kubectl get ksvc`

And see the pods scaling up when you hit the service URL e.g. `http://helloworld-go.default.35.238.83.86.xip.io/`


`kubectl get pods`

Now if you are here then the happy path has worked for you. Let scale down the cluster get some sleep !

` gcloud container clusters resize knative-demo --num-nodes=0 --zone=us-central1-c `

You should delete cluster if you are willing to setup knative (including istio n stuff) all over again when you do this again on a new cluster.

I am exploring [microk8s](https://microk8s.io/) which gives a way to run kubernetes cluster in local machine and enable knative with just like `microk8s enable knative`. Then you don't need to burn on GKE. 



