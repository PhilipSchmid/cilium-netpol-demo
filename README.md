# Demo of (Advanced) Cilium Network Policies 
This is a demo of how to lock down your Kubernetes cluster using advanced [Cilium Network Policies](https://docs.cilium.io/en/stable/security/policy/). For simplicity's sake, this demo assumes a green-field deployment of a new Kubernetes cluster with some common infrastructure components.

![architecture overview](pictures/architecture-overview.jpg)

If you would like to apply those or similar policies to your existing clusters, it's still possible without too much effort by leveraging Cilium Hubble's visibility capabilities to see if a newly introduced Cilium Network Policy causes unwanted traffic denies or not. You should check out Isovalent's free [Zero Trust hands-on lab](https://isovalent.com/labs/cilium-enterprise-zero-trust-visibility/) in case you are eager to learn more about our recommended way of validating new Cilium Network Policies before applying them to existing clusters.

* Go to the `slides` directory to see slide decks of talks I did based on this demo setup.
* Head over to the `deploy` directory to see how the demo Kubeadm Kubernetes cluster and infrastructure components are deployed.
* Check the `netpols/no-host-policies` directory to see the actual Cilium (Cluster-wide) Network Policies.
* Check the `netpols/with-host-policies` directory to see the actual Cilium (Cluster-wide) Network Policies where Cilium Host Policies are used as well (Host Firewall).

More examples and even hands-on labs on how to leverage Cilium Network Policies can be found in the free [Isovalent "Security Professional" learning track](https://isovalent.com/learning-tracks/#securityProfessionals).