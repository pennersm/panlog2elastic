# pan-elk

set up an elasticsearch ELK-stack to receive NGFW logs
comes up with kibana preconfigured to
  - index the data reasonably for searches
  - index lifecycle management  

##COMPONENTS:
  - terraform provisioning of suitable linux host
  (currently in EC2/AWS only)
  - ansible playbook to prepare linux environment
  - docker environment to run elastic application
  - scripts (carrots) to feed pan-elk (under kibana dir tree)  
  - our actual config is a bit hidden deep in the tree: ``docker/elk/kibana/pan-elk``


## STATUS:
  skelleton with ansible and terraform working
  all resources deployed and hooks ansible<->shellscripts<->terraform OK  
  If your FW is sending logs, then you should already see them coming in
  to your public IP (syslog UDP port is set in the FW log-forwarding profile)

  **NEXT TO DO:**
  - add kvm instead of AWS
  - change that horrible X509/certs setup to "simple" and add a vault for keys
  - dashboards ...
  - put the whole pan-elk into a native K8/ECS deployment


## STEPS AND USAGE:

1.  set your variables in variables.tf
    - aws account
    - EC2 settings
    - ansible playbook and terraform interaction
    - docker compose context


2.  run terraform (needs variables.tf)
    - creates AWS EC2 instance
    - provisions dockerfile to EC2 instance
    - creates ansible inventory
    - run ansible


3.  ansible actions
    - terraform auto-creates the host file
    - ansible is kicked-off by terraform ```shell_script``` resource
    - hardcoded timeout in playbook to wait for EC2 SSH  
    - only one playbook is ran straight no roles (needed) yet
    - playbook runs docker-compose in last step as user ubuntu

  - **anisble plays:**
    - install a bunch of ubuntu basic-addition packages (hardcoded)
    - set up FW (ports are hardcoded)
    - install docker (containerd CRT + docker-compose)
    - reboot and reconnect
    - run pre-provisioned (terraform EC2) dockerfile as ubuntu

4.  docker

    > we fetch the regular container images from elasticsearch docker repo the idea is to try and NOT modify (i.e. build) those images but to only change the entrypoint in a way that fits our orchestration needs
    Currently this is controlled by checking the availability of certificate files and by sending API calls once the containers are up

  - default docker-compose.yml file only starts 3 containers ls, es, kibana. they come up with fresh certificates/SSL-keys each time
  - ANY CHANGES to default ES cluster topology are made in the docker compose file. AND you MUST have those changes reflected in docker-compose .env file  (docker directory)
  - information from .env is not only used by docker compose but also by
    1. local scripts that set up the environment for docker compose
    2. the pan-elk scripts to fetch info to configure the cluster via API

## Open Points

-   **can not use company/fed account on AWS**   
    it looks like the company account does not allow direct login without using a 2FA-link and hence aws cli and terraform can not use it properly  
    this is a problem in so far that we need an EC2 which is larger than free-tier capacity  

-   **reachability of ports in AWS**
    it seems that UDP traffic is not always reaching the predefined ports and might even vary depending on your ISP or VPN settings

    if you can not get it work on UDP in your situation try to send TCP logs (change config in FW). Terraformm config is changed up to further to allow/ACL both, 5500-5599 UDP or TCP

    if you can not reach kibana or other TCP ports try to use the nginx config that is also provided. It enables a reverse-proxy to 127.0.0.1:5601 in this example config

    Note that kibana wont answer at all regardless what connectivity you offer if the server paths are not defined proper in kibana.yml  

## issues

-  **Heap size in production**
    Do not forget when entering a real env to change the heap sizes in jvm.options to something suitable
-   **SSL and security settings**
    For some reason kibana does not allow to be contacted via a https call and only does plaintext
    most testing here was done with different machines that all have same ubuntu version and Browser
    - find out if that problem really replicates elsewhere
    - if it does then fix config or track to bug
    Note that this is only for browser-to-kibana while all other SSL internally works aggregate
