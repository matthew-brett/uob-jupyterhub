# Setting up the UoB JupyterHub

<https://zero-to-jupyterhub.readthedocs.io/en/latest/>

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
--- but each *region* has three *zones*.  I've specified zone b --- see the
`vars.sh` file.


I believe the standard JupyterHub / Kubernetes setup uses a Service to route
requests from the proxy.  I made a static IP address, following [this
tutorial](https://cloud.google.com/kubernetes-engine/docs/tutorials/configuring-domain-name-static-ip):


```
gcloud compute addresses create uobhub-ip --region europe-west2
gcloud compute addresses describe uobhub-ip --region europe-west2
```

## Procedure

### Once only

Install Helm v2 in local filesystem:

```
. install_helm.sh
source ~/.bashrc
```

### Each time you restart the cloud console

Source the `vars.sh` file:

```
source vars.sh
```

### Kubernetes

Create the main cluster.

```
gcloud container clusters create \
  --machine-type n1-standard-2 \
  --num-nodes 2 \
  --cluster-version latest \
  --node-locations $ZONE \
  --region $REGION \
  $JHUB_CLUSTER
```

> Give your account permissions to perform all administrative actions needed.

```
kubectl create clusterrolebinding cluster-admin-binding \
  --clusterrole=cluster-admin \
  --user=$EMAIL
```

Optional - create a special user cluster.

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

### Helm

Now:
<https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-helm.html>.

All commands in web console:

> Set up a ServiceAccount for use by tiller.

```
kubectl --namespace kube-system create serviceaccount tiller
```

> Give the ServiceAccount full permissions to manage the cluster.

See caveat in docs about RBAC.  I ignored the caveat.

```
kubectl create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller
```

> Initialize helm and tiller.

```
helm init --service-account tiller --history-max 100 --wait
```

Note message

```
Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://v2.helm.sh/docs/securing_installation/
```

> Ensure that tiller is secure from access inside the cluster:

```
kubectl patch deployment tiller-deploy --namespace=kube-system --type=json --patch='[{"op": "add", "path": "/spec/template/spec/containers/0/command", "value": ["/tiller", "--listen=localhost:44134"]}]'
```

### JupyterHub

<https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html>

Make `config.yaml` as in the instructions.

Add JupyterHub Helm chart repository:

```
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update
```

Apply Helm chart.

```
helm upgrade --install $RELEASE jupyterhub/jupyterhub \
  --namespace $NAMESPACE  \
  --version=$JHUB_VERSION \
  --values config.yaml
```

Optional, autocompletion:

```
kubectl config set-context $(kubectl config current-context) --namespace ${NAMESPACE:-jhub}
```

To check what is running, after starting help upgrade above:

```
kubectl get pod --namespace $NAMESPACE
```

Once `hub` and `proxy` are running:

```
kubectl get service --namespace $NAMESPACE
```

to show the external IP address.

## Set up HTTPS

<https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/security.html#https>

Don't forget to reserve the IP (see above).

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
. vars.sh
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

I started using:

```
    name: gcr.io/ucb-datahub-2018/workshop-user-image
    tag: 3cd7a6b
```

I believe this is none other than the result of `docker build`ing
`deployments/datahub/images/default` from
<https://github.com/berkeley-dsep-infra/datahub> `staging` branch, as of
`258cdbc`.  I had to disable the JupyterLab stuff at the end, as it was
causing an error.

## Logging, login

```
kubectl logs pod/$(kubectl get pods -o custom-columns=POD:metadata.name | grep autohttps-) traefik -f
```

```
kubectl exec --stdin --tty autohttps-77dfc9d56c-8qdtt -- /bin/sh
```

## RStudio

Hmmm.

## Authentication

See
<https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/authentication.html#authenticating-with-oauth2>.

Example, for Github.

```
auth:
  type: github
  github:
    clientId: "y0urg1thubc1ient1d"
    clientSecret: "an0ther1ongs3cretstr1ng"
    callbackUrl: "http://uobhub.org/hub/oauth_callback"
```

## Nbgitpuller

Needs to be installed in the Docker container.

There is a [link builder](https://jupyterhub.github.io/nbgitpuller/link.html)
but it didn't refresh the link correctly for me.  I ended up crafting the links by hand, from [the url options](https://jupyterhub.github.io/nbgitpuller/topic/url-options.html).

* A Jupyter notebook link:
  <http://uobhub.org/user/matthew-brett/git-pull?repo=https%3A%2F%2Fgithub.com%2Fmatthew-brett%2Fdatasets&urlpath=mosquito_beer/process_mosquito_beer.ipynb>
* A link opening RStudio:
  <http://uobhub.org/user/matthew-brett/git-pull?repo=https%3A%2F%2Fgithub.com%2Fmatthew-brett%2Ftitanic-r&urlpath=/rstudio>.
  Titanic R exercise</a> and open in RStudio. RStudio will open, then
  use File - Open to open "titanic-r/titanic.Rmd" notebook.

See the URL options link above; it's not possible, at the moment, to get a
link that opens a particular R notebook directly in RStudio.

## Upgrade / downgrade number of nodes

Change max number of nodes with the [node-pools update
command](https://cloud.google.com/sdk/gcloud/reference/container/clusters/update):

```
. vars.sh
gcloud beta container node-pools update user-pool --region=$REGIO
N --cluster=jhub-cluster --max-nodes=20
```

Show the change:

```
gcloud beta container node-pools describe user-pool --region=$REGION --cluster=jhub-cluster
```
