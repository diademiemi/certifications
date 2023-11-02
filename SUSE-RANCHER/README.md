# SUSE Rancher
Rancher is a software stack for Kubernetes. Rancher provides many tools such as RKE (Rancher Kubernetes Engine), K3S, Rancher Manager, Longhorn, Fleet and more. 

Everything in Rancher is managed by Rancher Manager. Rancher Manager is a web-based UI that allows you to manage Kubernetes clusters, namespaces, projects, users, etc. All of these products are open source and free to use.  

To practice for exams relating to Rancher (sca-rancher-2-6, scds_rancher_mgt_2_7, scds-ran-k8s), I have built a homelab around Rancher. You can find this project here:
[https://github.com/diademiemi/homelab](https://github.com/diademiemi/homelab)  

This homelab makes use of K3S, Rancher Manager (With Terraform), Fleet and Longhorn and more tools outside of Rancher. More information can be found in the README of the homelab project.  
The README contains more documentation on how I used Rancher to build my homelab, which is how I practiced for the exams!

You may need to look at an older commit in order to find the exact software stack I used to practice this exam (including OPA gatekeeper & CIS scans), [diademiemi/homelab@8f8d399d24937244417892ce41560484b897b436](https://github.com/diademiemi/homelab/tree/8f8d399d24937244417892ce41560484b897b436) should include everything!