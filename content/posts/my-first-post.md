+++
title = 'First Official Publishing'
date = 2024-09-18T15:07:03-07:00
draft = true
+++

## WELCOME!
Hello, and welcome to my first official site post! Thank you for taking the time to review this content. I had never in the past created a website, but I was motivated to do so to learn more about building and deploying software. My first project is to build a dummy site which runs on Apache2 web server from an EC2 Ubuntu instance. The reasoning for this being that this site was built using Hugo, a Static Site Generator.

## EC2/SSH Configuration
In order to build and deploy my site, I required a server to run all my services and store my files. I chose an AWS EC2 Ubuntu instance for this exercise, to also learn how to better work with Linux. This also made sense so I could learn what it takes to launch a full web-site.

Once my EC2 instance was up and running and once I had functional SSH access, it was time to SSH onto my machine and begin the work. First step was to install Apache2 on my EC2 instance and verify it was functional:
```shell
sudo apt install apache2
systemctl status apache2
curl https://ipinfo.io/ip
```
I used the third command to find my public IP address so I can verify outside connectivity to my server.

After validating functionality, my next step was to download Hugo, install Hugo in a location accessible to my PATH, and delete the extra files:
```shell
cd /usr/bin/
sudo wget https://github.com/gohugoio/hugo/releases/download/v0.134.2/hugo_extended_0.134.2_linux-amd64.tar.gz
sudo tar -xvzf hugo_extended_0.134.2_linux-amd64.tar.gz -C hugoFiles
sudo mv hugoFiles/hugo hugo
sudo rm -fr hugoFiles
sudo rm -f hugo_extended_0.134.2_linux-amd64.tar.gz
```
You can confirm a successfull install running
```
hugo version
hugo v0.134.2-1c74abd26070b0c12849550c974a9f3f1e7afb06+extended windows/amd64 BuildDate=2024-09-10T10:46:33Z VendorInfo=gohugoio
```

Next up, we moved to our HOME directory where we could create our Hugo project files and complete the initial configuration using the Ananke theme. This will allow you to run the command to build and preview a bare-bone web site:
``` shell
cd ~
hugo new site quickStart
cd quickStart
git init
git submodule add https://github.com/theNewDynamic/gohugo-theme-ananke.git themes/ananke
echo theme = 'ananke' >> hugo.toml
hugo server
```
You can also configure the `.gitignore` file at this point to ignore some of the build files`public/1, 1.hugo_build.lock`, and `resources/`. At this point, you have a baseline web site. Make sure to save all changes, commit them with git, and `push` the changes to a version control system for future needs and changes!

## Apache2 Web Server Configuration
Again, the choice for Apache2 was to easily configure a web server while at the same time learn how to configure and manage one. If you haven't already done so, follow the steps in the EC2/SSH Configuration section to install Apache2 web server and validate installation.

If all is correct, we will disable our default page:
```
sudo a2dissite 000-default.conf
systemctl reload apache2
```

Next, we will configure the firewall to practice best-security-practices. To see which applications can be configured by Ubuntu's firewall, run
```shell
sudo ufw app list
# Output:
# Available applications:
#   Apache
#   Apache Full
#   Apache Secure
#   OpenSSH
```
We will allow `Apache Full` and `OpenSSH`. We need to include OpenSSH or else when we enable our firewall, we will lose our SSH connection and will be unable to re-connect without lots and lots of work, if then:
```shell
sudo ufw allow 'Apache Full'
sudo ufw allow OpenSSH
sudo ufw status
# Output:
#  Status: disabled
sudo ufw enable
sudo ufw status
# Output
#  Status: active
#
#  To                         Action      From
#  --                         ------      ----
#  Apache Full                ALLOW       Anywhere                  
#  OpenSSH                    ALLOW       Anywhere                  
#  Apache Full (v6)           ALLOW       Anywhere (v6)             
#  OpenSSH (v6)               ALLOW       Anywhere (v6)  
```

## Resources
If you are interested in any of the resources I used, they were the following:
* [The Hugo Quick-Start Guide](https://gohugo.io/getting-started/quick-start/)
* An EC2 Ubuntu instance from AWS, running Apache2 web server
* Git, for source control
* [AM Cloud Solution's Hosting Hugo blog post](https://amcloudsolutions.de/en/blog/hosting-hugo/)