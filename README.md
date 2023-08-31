# ASG-ALB-TG-with-Terraform
AutoScalingGroup with terraform

Creating a Load Balancing between a cluster of web servers on AWS with Terraform
this repo is an example of using ELB Elastic Load Balancing with ASG Auto Scaling Group to provide highly available and efficient web servers

Deploy a Cluster of Web Servers
we will use ASG to launch a cluster of EC2 Instances, monitoring the health of each Instance, replacing failed Instances, and adjusting the size of the cluster in response to load.

ASG distributes the EC2 instances across multiple availability zones
each AWS account has access to different set of Availability zones, in this repo, i've choosed all availability zones available in my account
Deploy a Load Balancer
after deploying the ASG you'll have serveral different servers, each with its own ip address, but you need to give your end users only a single IP to hit, and for this we're going to deploy a load balancer to distribute traffic accross your servers and to give your end users a single dns name which is the the load balancer dns name
