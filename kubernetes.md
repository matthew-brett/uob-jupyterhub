# Kubernetes basics

## Very broad overview

Kubernetes allows you to specify recipes for clusters, and run the cluster
according to these recipes.

Clusters contain virtual machines, called *nodes*.

The cluster has a defined set of managing processes, collectively known as the *control plane*.

A *node* contains *pods*.  In standard use, a *pod* is a wrapper around
a single container, such as a Docker container.  Pods in the same node can
talk to each other.

## More detail overview

<https://kubernetes.io/docs/concepts/overview/>

> Kubernetes is a portable, extensible, open-source platform for managing
> containerized workloads and services

<https://kubernetes.io/docs/concepts/overview/components/>

See graphic on that page for overview.

## Cluster

> A Kubernetes cluster consists of a set of worker machines, called nodes,
> that run containerized applications.

## Control plane

> The control plane manages the worker nodes and the Pods in the cluster. In
> production environments, the control plane usually runs across multiple
> computers.

It consists of the following *components*.

* kube-apiserver : exposes the Kubernetes API
* etcd : key-value store
* kube-scheduler : "watches for newly created Pods with no assigned node, and
  selects a node for them to run on".
* kube-controller-manager : runs controllers for nodes, replication, endpoints
  and service account / tokens.
* cloud-controller-manager : "lets you link your cluster into your cloud
  provider's API ... only runs controllers that are specific to your cloud
  provider."

## Node

A *node* is a machine, or virtual machine.  It hosts *pods*.

> The worker node(s) host the Pods that are the components of the application
> workload.

### Node components

<https://kubernetes.io/docs/concepts/overview/components/#node-components>

> Node components run on every node, maintaining running pods and providing
> the Kubernetes runtime environment.

* kubelet : makes sure containers running in pods match their PodSpecs.
* kube-proxy : maintains network rules on nodes.
* container-runtime : software that is responsible for running containers,
  e.g. Docker.

## Pod

<https://kubernetes.io/docs/concepts/workloads/pods>

> A Pod (as in a pod of whales or pea pod) is a group of one or more
> containers, with shared storage/network resources, and a specification for
> how to run the containers. ... A Pod models an application-specific "logical
> host": it contains one or more application containers which are relatively
> tightly coupled.

> In terms of Docker concepts, a Pod is similar to a group of Docker
> containers with shared namespaces and shared filesystem volumes.

> The "one-container-per-Pod" model is the most common Kubernetes use case; in
> this case, you can think of a Pod as a wrapper around a single container.

### PodTemplate

> PodTemplates are specifications for creating Pods, and are included in
> workload resources such as Deployments, Jobs, and DaemonSets.

## Storage notes

<https://kubernetes.io/docs/concepts/storage/>

### Volume

> At its core, a volume is just a directory, possibly with some data in it,
> which is accessible to the Containers in a Pod.

### Persistent volume

<https://kubernetes.io/docs/concepts/storage/persistent-volumes/>

> A PersistentVolume (PV) is a piece of storage in the cluster that has been
> provisioned by an administrator or dynamically provisioned using Storage
> Classes.

You can provision PV's in two ways:

* static : the administrator creates these.
* dynamic : cluster tries to create the storage, using a StorageClass. "This
  provisioning is based on StorageClasses: the PVC must request a storage
  class and the administrator must have created and configured that class for
  dynamic provisioning to occur."

### Persistent volume claim

> A PersistentVolumeClaim (PVC) is a request for storage by a user. It is
> similar to a Pod. Pods consume node resources and PVCs consume PV resources.


### NFS

<https://github.com/kubernetes/examples/tree/master/staging/volumes/nfs>
