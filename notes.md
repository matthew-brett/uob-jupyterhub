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

I initially used the web shell via the [web
console](https://console.cloud.google.com).  The web shell wouldn't start on
Firefox, so I went to Chrome.  Later I installed the [Google Cloud
SDK](https://cloud.google.com/sdk) locally, as I got bored of being automatically disconnected from the web shell.

`europe-west2` appears to be the right *region* for the UK:
<https://cloud.google.com/compute/docs/regions-zones/#available>.

Regions contain *zones*.  See the
[docs](https://cloud.google.com/sdk/gcloud/reference/container/clusters/create)
I've specified zone b --- see the `vars.sh` file.

## Authenticate

Otherwise you'll get `The connection to the server localhost:8080 was refused`
for various commands.

```
gcloud auth login
```

maybe followed by:

```
. vars.sh
CLUSTER=${JHUB_CLUSTER}  # or whatever
gcloud container clusters get-credentials $CLUSTER --region $REGION
```

<https://stackoverflow.com/a/57592322/1939576>

## Documentation links

* <https://kubernetes.io/docs/reference/kubectl/cheatsheet>

## Static IP addresses

I believe the standard JupyterHub / Kubernetes setup uses a Service to route
requests from the proxy.  I made a static IP address, following [this
tutorial](https://cloud.google.com/kubernetes-engine/docs/tutorials/configuring-domain-name-static-ip):

```
gcloud compute addresses create uobhub-ip --region europe-west2
gcloud compute addresses describe uobhub-ip --region europe-west2
```

Note the IP address from above in the `vars.sh` file and the `loadBalancerIP`
field of `config.sh`.

Set up DNS to point to this IP.  Wait for it to propagate, at least to the
console you are using, e.g.

```
nslookup uobhub.org
```

Set the host name in your `config.yaml`.

## Billing data

You'll need this!  Honestly.  The money runs out quickly if you're not keeping
track of where it's going.

I set up a billing table to export to, via the Google Billing Export panel,
called `uob_jupyterhub_billing`.

## Scaling

Be careful when scaling.  I had a demo crash catastrophically when more than
32 or so people tried to log in - see [this discourse thread for some
excellent help and
discussion](https://discourse.jupyter.org/t/scheduler-insufficient-memory-waiting-errors-any-suggestions/5314).
If you want to scale to more than a few users, you will need to:

* Make sure you have enough nodes in the user pool - see section: "Upgrade
  / downgrade number of nodes"
* Specify minimum memory and CPU requirements carefully.  See [this section of
  the
  docs](https://zero-to-jupyterhub.readthedocs.io/en/latest/customizing/user-resources.html#set-user-memory-and-cpu-guarantees-limits).
  As those docs point out, by default each user is guaranteed 1G of RAM, so
  each new user will add 1G of required RAM.  This in turn means that fewer
  users will fit onto one node (VM), and you'll need more VMs, and therefore
  more money, and more implied CPUs (see below).
* You may need to increase your CPU quotas on Google Cloud to allow many users
  - try [this
  link](https://console.cloud.google.com/iam-admin/quotas?pageState=(%22allQuotasTable%22:(%22f%22:%22%255B%257B_22k_22_3A_227%2520Day%2520Peak%2520Usage_22_2C_22t_22_3A1_2C_22v_22_3A_22%257B_5C_22v_5C_22_3A_5C_220_5C_22_2C_5C_22o_5C_22_3A_5C_22%253E_5C_22%257D_22_2C_22i_22_3A_22seven-day-peak-usage_22%257D_2C%257B_22k_22_3A_22_22_2C_22t_22_3A10_2C_22v_22_3A_22_5C_22CPUs_5C_22_22%257D%255D%22,%22s%22:%5B(%22i%22:%22seven-day-peak-usage%22,%22s%22:%221%22),(%22i%22:%22service%22,%22s%22:%220%22)%5D)))
  to ask for modification of your quota.

## Storage

Follow steps in `./storage.md` to create home directories / data disk, served by NFS.

## Local Helm

Install Helm v2 in `$HOME/usr/local/bin` filesystem:

```
. install_helm.sh
source ~/.bashrc
```

## Examples

There are various examples of configuration in
<https://github.com/berkeley-dsep-infra/datahub/tree/staging/deployments>,
with some overview in the [datahub
docs](https://docs.datahub.berkeley.edu/en/latest/users/hubs.html).

## Keeping secrets

See
<https://discourse.jupyter.org/t/best-practices-for-secrets-in-z2jh-deployments/1292>
and <https://github.com/berkeley-dsep-infra/datahub/issues/596>.

## The whole thing

I used a new project.  You'll need an IP and domain name for cluster, as above,
and maybe authentication, see below.

* Edit `vars.sh` to record IP, Google project name and other edits to taste.
* Edit `config.yaml` to record domain name etc.
* Run:

```
# Initialize cluster
source init_gcloud.sh
```

```
# Initialize Kubernetes
source init_kubernetes.sh
```

```
# Initialize Helm
source setup_helm.sh
```

```
# Initialize NFS
source init_nfs.sh
```

```
# Configure cluster by applying Helm chart
source configure_jhub.sh
```

Test https.   You might need to:

```
# Reset https on cluster
source reset_autohttps.sh
```

My `config.yaml.cleaned` and `vars.sh` are for a fairly low-spec, but scalable
cluster.

## Procedure in steps

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

See caveat in docs about RBAC.  The Google Kubernetes setup does use RBAC, so
the caveat did not apply to me.

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

> Ensure that tiller is [secure from access inside the cluster](https://engineering.bitnami.com/articles/helm-security.html):

```
kubectl patch deployment tiller-deploy --namespace=kube-system --type=json --patch='[{"op": "add", "path": "/spec/template/spec/containers/0/command", "value": ["/tiller", "--listen=localhost:44134"]}]'
```

### JupyterHub

<https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html>

Make `config.yaml` as in the instructions.  See `config.yaml.cleaned` for a
sanitized version.

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

This proved tricky.  See [this
post](https://discourse.jupyter.org/t/trouble-getting-https-letsencrypt-working-with-0-9-0-beta-4/3583/5?u=matthew.brett)
for details, following the [kind suggestions by Erik
Sundell](https://discourse.jupyter.org/t/trouble-getting-https-letsencrypt-working-with-0-9-0-beta-4/3583/4?u=matthew.brett).

I found and deleted the secret:

```
kubectl get secrets
kubectl delete secret proxy-public-tls-acme
kubectl get secrets
```

I found the latest chart from <https://jupyterhub.github.io/helm-chart/#development-releases-jupyterhub>, which was `0.9.0-n116.h1c766a1`.

I then purged and restarted using this chart:

```
$ helm delete $RELEASE --purge
$ helm upgrade --install $RELEASE jupyterhub/jupyterhub --namespace $NAMESPACE --version=$JHUB_VERSION --values config.yaml
```

Then I checked the logs, but got the same error:

```
$ kubectl logs pod/$(kubectl get pods -o custom-columns=POD:metadata.name | grep autohttps-) traefik -f
```

giving:

```
time="2020-07-03T17:46:42Z" level=error msg="Unable to obtain ACME certificate for domains \"testing.uobhub.org\" : unable to generate a certificate for th
e domains [testing.uobhub.org]: error: one or more domains had a problem:\n[testing.uobhub.org] acme: error: 400 :: urn:ietf:params:acme:error:connection :
: Fetching http://testing.uobhub.org/.well-known/acme-challenge/QfUNDgaKU_3dw_WvkDiPaAADbFAOciVMXCMG99nZCiI: Timeout during connect (likely firewall proble
m), url: \n" providerName=default.acme
```

Finally, I tried deleting the `autohttps` pod:

```
$ kubectl delete pods $(kubectl get pods -o custom-columns=POD:metadata.name | grep autohttps-)
```

And - hey presto - it worked!

Check https access with a [Qualsys SSL labs URL in your
browser](https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/security.html#confirm-that-your-domain-is-running-https).

## Upgrade to new helm chart

```
. vars.sh
helm upgrade $RELEASE jupyterhub/jupyterhub  --version=$JHUB_VERSION --values config.yaml
```

## Securing

<https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/security.html>

> ... mitigate [root access to pods] by limiting public access to the Tiller API.

This is covered by the command below - already in the recipe above:

```
kubectl --namespace=kube-system patch deployment tiller-deploy --type=json --patch='[{"op": "add", "path": "/spec/template/spec/containers/0/command", "value": ["/tiller", "--listen=localhost:44134"]}]'
```

The Dashboard can show information about the cluster that should not be public.  Delete the dashboard with:

```
kubectl --namespace=kube-system delete deployment kubernetes-dashboard
```

On my system, this gave a "NotFound" error, and the [following
command](https://stackoverflow.com/a/49427146) gave no output.

```
kubectl get secret,sa,role,rolebinding,services,deployments,pods --all-namespaces | grep dashboard
```

See also [JupyterHub
security](https://jupyterhub.readthedocs.io/en/stable/reference/websecurity.html).

## Security review

Following the headings in the link above:

* HTTPS: enabled via LetsEncrypt
* Secure access to Helm : using Helm 3, patch no longer relevant.
* Audit Cloud Metadata server access: access blocked by default (and not
enabled by me).
* Delete the Kubernetes Dashboard: checked - dashboard not running
* Use Role Based Access Control (RBAC): Google uses RBAC, thus enabled by default.
* Kubernetes API Access: disabled by default (and not enabled by me).
* Kubernetes Network Policies: disabled by default (and not enabled by me).

The Helm charts hosted via <https://jupyterhub.github.io/helm-chart>.  At time
of writing (2020-09-12), I'm using the latest devel version,
`0.9.0-n233.hcd1eff7a` - see `./vars.sh`.

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

Finding the `autohttps` pod, getting logs:

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

### For testing

See e.g. <https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/authentication.html#adding-a-whitelist>

```
# Anyone can log in with any username and any password.
auth:
  type: dummy
```

or, for a little extra security:

```
# Anyone can log in with any username, but they must use this password.
auth:
  type: dummy
  dummy:
    password: 'mypassword'
```


### CILogon authentication

See [Z2JH
section](https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/authentication.html#cilogon)
and [the CILogon docs](https://www.cilogon.org/oidc#h.p_PEQXL8QUjsQm).

Go to <https://cilogon.org/oauth2/register> and ask for your JupyterHub client to be registered.  As noted in the CILogon docs above, you should ask for these three scopes: *openid*, *email*, and *org.cilogon.userinfo*.  I found their support to be very quick and helpful.

You might want to restrict authentication providers by specifying one from the
list at <https://cilogon.org/include/idplist.xml> (see
`c.CILogonOAuthenticator.idp` below).

Here's a fake version of my eventual config:

```
auth:
  type: cilogon
  cilogon:
    # See: https://www.cilogon.org/oidc#h.p_PEQXL8QUjsQm
    clientId: cilogon:/client_id/a0b1c2d3e4f56789a0b1c2d3e4f56789
    clientSecret: a0b1c2d3e4f56789a0b1c2d3e4f-a0b1c2d3e4f56789a0b1c2d3e4f56789a0b1c2d3e4f56789a0b1c2d3e4
    callbackUrl: https://uobhub.org/hub/oauth_callback

hub:
  extraConfig:
    myAuthConfig: |
      # Default ePPN username claim works for UoB; no need to force "email",
      # but do this anyway for consistency.
      c.CILogonOAuthenticator.username_claim = 'email'
      c.CILogonOAuthenticator.idp = 'https://idp.bham.ac.uk/shibboleth'
      # Stripping only works for a single entry in whitelist below.
      c.CILogonOAuthenticator.strip_idp_domain = True
      # Will soon be "allowed_idps" (from v0.12 of oauthenticator)
      c.CILogonOAuthenticator.idp_whitelist = ['bham.ac.uk',
                                               'student.bham.ac.uk']

```

### Globus authentication

* [JH, Kubernetes auth for Globus](https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/authentication.html#globus)
* [OAthenticator](https://github.com/jupyterhub/oauthenticator)
* [Globus procedure](https://oauthenticator.readthedocs.io/en/latest/getting-started.html#globus-setup)

Make an app at <https://developers.globus.org>, and follow instructions at [OAuthenticator Globus setup](https://oauthenticator.readthedocs.io/en/latest/getting-started.html#globus-setup).

As instructed, I enabled the scropes "openid profile
urn:globus:auth:scope:transfer.api.globus.org:all".  I set the callback URL as
below, and checked "Require that the user has linked an identity ...", and
"Pre-select a specific identity", both set to my university. I then copied the client id given (see below), and made a new client secret (see below).

Example adapted from [JH, Kubernetes auth for Globus](https://zero-to-jupyterhub.readthedocs.io/en/latest/administrator/authentication.html#globus):

```
auth:
  type: globus
  globus:
    clientId: a0b1c2d3-a0b1-a0b1-a0b1-a0b1c2d3e4f5
    clientSecret: a0b1c2d3e4f56789a0b1c2d3e4f56789a0b1c2d3e4f5
    callbackUrl: https://uobhub.org/hub/oauth_callback
    identityProvider: bham.ac.uk
```

I ran into problems with this auth, for our students, for some reason, so switched to CILogon above.

## Nbgitpuller

Needs to be installed in the Docker container.

There is a [link builder](https://jupyterhub.github.io/nbgitpuller/link.html)
but it didn't refresh the link correctly for me.  I ended up crafting the links by hand, from [the url options](https://jupyterhub.github.io/nbgitpuller/topic/url-options.html).

* A Jupyter notebook link:
  <http://uobhub.org/user/matthew-brett/git-pull?repo=https%3A%2F%2Fgithub.com%2Fmatthew-brett%2Fdatasets&urlpath=mosquito_beer/process_mosquito_beer.ipynb>
* A link opening RStudio:
  <http://uobhub.org/user/matthew-brett/git-pull?repo=https%3A%2F%2Fgithub.com%2Fmatthew-brett%2Ftitanic-r&urlpath=/rstudio>.
  This fetches the [Titanic R exercise from
  Github](https://github.com/matthew-brett/titanic-r/blob/master/titanic.Rmd)
  and opens RStudio. In RStudio, use File - Open to open the
  `titanic-r/titanic.Rmd` notebook.

See the URL options link above; it's not possible, at the moment, to get a
link that opens a particular R notebook directly in RStudio.

## Helm charts

[JupyterHub Helm chart listing](https://jupyterhub.github.io/helm-chart/#development-releases-jupyterhub).

## Upgrade / downgrade number of nodes

Change max number of nodes with the [node-pools update
command](https://cloud.google.com/sdk/gcloud/reference/container/clusters/update):

```
. vars.sh
gcloud beta container node-pools update user-pool --region=$REGION --cluster=${JHUB_CLUSTER} --max-nodes=50
```

Show the change:

```
gcloud beta container node-pools describe user-pool --region=$REGION --cluster=${JHUB_CLUSTER}
```

## Contexts

If futzing around between a couple of clusters, you may have to change
"contexts" - see [this gh
issue](https://github.com/kubernetes/kubernetes/issues/56747).

```
$ kubectl config current-context
error: current-context is not set
$  kubectl config get-contexts
CURRENT   NAME                                           CLUSTER                                        AUTHINFO                                       NAMESPACE
          gke_uob-jupyterhub_europe-west2_jhub-cluster   gke_uob-jupyterhub_europe-west2_jhub-cluster   gke_uob-jupyterhub_europe-west2_jhub-cluster   jhub
$ kubectl config use-context gke_uob-jupyterhub_europe-west2_jhub-cluster
```

## Tuning performance, scaling, cost

Be careful when scaling.  I had a demo crash catastrophically when more than
32 or so people tried to log in - see [this discourse thread for some
excellent help and
discussion](https://discourse.jupyter.org/t/scheduler-insufficient-memory-waiting-errors-any-suggestions/5314).

See also:

* [Discussion of factors increasing
resilience](https://discourse.jupyter.org/t/core-component-resilience-reliability/5433).
* <https://discourse.jupyter.org/t/background-for-jupyterhub-kubernetes-cost-calculations/5289/5>

You can do a preliminary test of scaling by asking for a large number of *user placeholder* pods.  This does some simulation of starting multiple pods at the same time.

For example:

```
scheduling:
  userScheduler:
    enabled: true
  podPriority:
    enabled: true
  userPlaceholder:
    # Specify number of dummy user pods to be used as placeholders
    enabled: true
    replicas: 250
  userPods:
    nodeAffinity:
      # matchNodePurpose valid options:
      # - ignore
      # - prefer (the default)
      # - require
      matchNodePurpose: require

jupyterhub:
  hub:
    # See this link for discussion of these options.
    # https://discourse.jupyter.org/t/core-component-resilience-reliability/5433/4
    activity_resolution: 120  # Default 30
    hub_activity_interval: 600  # Default 300
    last_activity_interval: 300  # Default 300
    init_spawners_timeout: 1  # Default 10
```

At time of writing, I also used a devel release of the JupyterHub Helm chart,
`0.9.0-n233.hcd1eff7a` in order to get an [August 2020 performance fix in the
KubeSpawner library](https://github.com/jupyterhub/kubespawner/issues/423);
see [this
thread](https://discourse.jupyter.org/t/core-component-resilience-reliability/5433/4).

Very good scaling may need a Postgres server rather than the default SQLite; I
haven't tried that.

Other aspects:

* Make sure you have enough nodes in the user pool - see section: "Upgrade /
  downgrade number of nodes"
* Specify minimum memory and CPU requirements carefully.  See [this section of
  the
  docs](https://zero-to-jupyterhub.readthedocs.io/en/latest/customizing/user-resources.html#set-user-memory-and-cpu-guarantees-limits).
  As those docs point out, by default each user is guaranteed 1G of RAM, so
  each new user will add 1G of required RAM.  This in turn means that fewer
  users will fit onto one node (VM), and you'll need more VMs, and therefore
  more money, and more implied CPUs (see below).

Be careful of quotas on your cloud system; see next section.

### Google cloud specifics

Thanks to Min R-K for pointing me to these fixes / links.

* If scaling fails check your [Google quotas
  page](https://console.cloud.google.com/iam-admin/quotas) to see if you've exhausted some quota, such as CPU, or internal IP addresses.
* It may be worth checking
  [GC monitoring](https://console.cloud.google.com/monitoring).
* You may well need to increase your CPU quotas on Google Cloud to allow
  enough nodes.  The number of nodes you need will depend on how many user
  pods can pack into one node.  You can ask to increase your CPU quota via the
  quotas page above.
* You may well need to increase your quota of internal network IP addresses,
  if you have many pods.  Check the quotas page above.
* You might try downgrading the machine types on which the cluster runs, from
  the suggested default of `n1-standard-2`, to save money, but be look out for
  out-of-memory errors stalling the cluster, in the logs and output of
  `kubetcl get pod`.  I managed to get down to `n1-custom-1-6656` (1 CPU,
  6.5GB of RAM), while still scaling to 250 pods, but I couldn't go lower
  without the cluster stalling.  See `DEFAULT_MACHINE` in `./vars.sh`.

The [Kubernetes workload
page](https://console.cloud.google.com/kubernetes/workload) can be useful to
review what the cluster etc is doing.

## Storage volumes

I'm using NFS, with a directory for storing home directories, and another for
storing read-only data.  See `./storage.md` and `./init_nfs.sh`.

See
<https://github.com/berkeley-dsep-infra/datahub/blob/de634c5/docs/admins/storage.rst>
for discussion of NFS.  See also the files there for matching Datahub / Data8x
setup.

See also discussion at <https://discourse.jupyter.org/t/additional-storage-volumes/5012/7>

