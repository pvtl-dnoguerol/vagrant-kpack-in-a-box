# Vagrant Kpack-in-a-Box

This repository is a set of Vagrant files and scripts that will perform the following functions:

* Use Vagrant to pave 3 VMs
* Install a 3-node Kubernetes cluster using a set of shell scripts based on the procedure outlined in "Kubernetes the Hard Way."
* Install Flannel as the CNI
* Install an Nginx Ingress Controller
* Install the Harbor container registry
* Install the kpack container build service

## Installation
The process is broken up into two steps: _creating the master node_ and _creating the worker nodes_.

### Creating the Master Node

From within the `master` directory...

1. Edit the `Vagrantfile` if needed, especially:
  * The `IFNAME` variable which may need to change based on what virtualization solution you are using).
  * The `HARBOR_DOMAIN` variable will need to change based on the TLS certificates you supply in the next step.
2. In the `tls` directory, replace the `tls.key` (private key) and `tls.crt` (public certificate) files with your own. This will determine the TLS certificate used by the ingress controller (and ultimately Harbor). _The ones included only reference localhost and are pretty much useless_.
3. Run the `vagrant up` command.
4. When the command finishes running, make note of the master node's IP address that is displayed.

### Creating the Worker Nodes

From within the `worker` directory...

1. Edit the `Vagrantfile` if needed (take a look at the `IFNAME` variable which may need to change based on what virtualization solution you are using).
2. Run the `vagrant up` command.
3. Enter the IP address returned in step 4 above and press ENTER. Note that this input is not particularly tolerant of whitespace, control characters, etc. so don't throw any curveballs at it.

## Usage

If all goes well, the Kubernetes cluster should be up and running.

From within the `master` directory...

1. Run `vagrant ssh master` which will get you into the master node. The `vagrant` and `root` users should both have `kubectl` properly configured to interact with Kubernetes. The `/root/.kube/config` is where the credentials are stored.
2. Confirm that you have pods running via `kubectl get pods --all-namespaces`. You should see ones for Flannel, CoreDNS, Nginx Ingress Controller, Harbor and Kpack.
2. Run the command: `kubectl get pods -n ingress-nginx -o wide` which will provide you the IP address of the node on which the ingress controller is running. This will be your entry point to Harbor (or any other applications you deploy that define an Ingress resource). Note that this address could change if Kubernetes has to restart the ingress container.
3. A quick and dirty solution is to modify your local machine's `/etc/hosts` file (or `c:\Windows\System32\Drivers\etc\hosts` on Windows) to point the Harbor domain you defined in step 1 to this IP address.
4. If all worked properly, you should be able to point your browser at `https://HARBOR_DOMAIN` and log into Harbor using the default user `admin` and password `Harbor12345`.