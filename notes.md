https://zero-to-jupyterhub.readthedocs.io/en/latest/

Then:

<https://zero-to-jupyterhub.readthedocs.io/en/latest/google/step-zero-gcp.html>

I added a budget to cap at the \$500 dollar limit, with default warnings.

I believe I cannot create a housing organization, because I am not a G-Suite or
Cloud Identity customer - see [this
page](https://cloud.google.com/resource-manager/docs/creating-managing-organization).

I created a project `uob-jupyterhub`.

I enabled the Kubernetes API via
<https://console.cloud.google.com/apis/library/container.googleapis.com>.

I used the web console.  It wouldn't start on Firefox, so I went to Chrome.

`europe-west2` appears to be the right *region* for the UK:
<https://cloud.google.com/compute/docs/regions-zones/#available>.

See the
[docs](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create)
--- but each *region* has three *zones*.  I've specified 

Source this file:

```
# vars.sh
# Source this file.
JHUB_CLUSTER=jhub-cluster
RELEASE=jhub
NAMESPACE=jhub
REGION=europe-west2
ZONE=europe-west2-b
EMAIL=matthew.brett@gmail.com
```

```
source vars.sh
```

```
gcloud container clusters create \
  --machine-type n1-standard-2 \
  --num-nodes 2 \
  --cluster-version latest \
  --node-locations $ZONE \
  --region $REGION \
  $JHUB_CLUSTER
```

```
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=$EMAIL
```

```
gcloud beta container node-pools create user-pool \
  --machine-type n1-standard-2 \
  --num-nodes 0 \
  --enable-autoscaling \
  --min-nodes 0 \
  --max-nodes 3 \
  --node-labels hub.jupyter.org/node-purpose=user \
  --node-taints hub.jupyter.org_dedicated=user:NoSchedule \
  --node-locations $ZONE \
  --region $REGION \
  --cluster $JHUB_CLUSTER
```

Now: <https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/index.html>

All commands in web console:

```
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
```

```
kubectl --namespace kube-system create serviceaccount tiller
```

See caveat in docs about RBAC.  I ignored the caveat.

```
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
```

```
helm init --service-account tiller --history-max 100 --wait
```

Note message

```
Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://v2.helm.sh/docs/securing_installation/
```

```
kubectl patch deployment tiller-deploy --namespace=kube-system --type=json --patch='[{"op": "add", "path": "/spec/template/spec/containers/0/command", "value": ["/tiller", "--listen=localhost:44134"]}]'
```

<https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html>

Make `config.yaml` as in the instructions.  Then:

```
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update
```

```
helm upgrade --install $RELEASE jupyterhub/jupyterhub \
  --namespace $NAMESPACE  \
  --version=0.9.0 \
  --values config.yaml
```

Optional, autocompletion:

```
kubectl config set-context $(kubectl config current-context) --namespace ${NAMESPACE:-jhub}
```

To check what is running, after starting help upgrade above:

```
kubectl get pod --namespace jhub
```

Once `hub` and `proxy` are running:

```
kubectl get service --namespace jhub
```

to show the external IP address.

## Set up HTTPS

<>

```
proxy:
  https:
    hosts:
      - uobhub.org
    letsencrypt:
      contactEmail: matthew.brett@gmail.com
  service:
    loadBalancerIP: 35.189.82.198
```

Upgrade:

```
. vars.sh
helm upgrade $RELEASE jupyterhub/jupyterhub  --version=$JHUB_VERSION --values config.yaml
```

## Tear it all down

```
RELEASE=jhub
NAMESPACE=jhub
helm delete $RELEASE --purge
kubectl delete namespace $NAMESPACE
```

## Dockerfiles

See <https://github.com/jupyter/docker-stacks>

In `config.yaml`, something like:

```
singleuser:
  image:
    # Get the latest image tag at:
    # https://hub.docker.com/r/jupyter/datascience-notebook/tags/
    # Inspect the Dockerfile at:
    # https://github.com/jupyter/docker-stacks/tree/master/datascience-notebook/Dockerfile
    name: jupyter/datascience-notebook
    tag: 54462805efcb
```

Don't forget the tag!

## RStudio
