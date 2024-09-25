+++
title = 'Standardizing and Automating my Build and Deployment'
date = 2024-09-24T14:33:52-07:00
draft = false
+++

# Standardizing and Automating the Build and Deploy Process
The next logical step in my development of my personal site, was to implement some form of automation which would help standardize my build process and automate the deployment of my site. Since I've also wanted to learn how to use Docker, I decided to use the tool to help standardize the site building.

## Configuring Docker on My EC2 Instance
The EC2 instance I currently use to host my site has a few tools installed to allow me to build and deploy my site. I did not have Docker installed, so I went online to find details on what was required and determined I only needed Docker Engine. To install:
```bash
sudo apt install docker.io -y
```
Once installed, I started the Docker service, ran a verification of the installation, and enabled the service to start automatically:
```bash
sudo systemctl start docker
sudo docker run hello-world
# You should see a confirmation message indicating Docker is working correctly at this point
sudo systemctl enable docker
```
The last step was to add my user to the Docker group to run my commands without the need for `sudo`:
```bash
sudo usermod -a -G docker $(whoami)
```

## Configuring the Dockerfile
Simply installing Docker was not enough to complete my desired goal; the next task was to create a Dockerfile for my site. The Dockerfile will be used by Docker to build my site from any system with Docker installed, meaning my builds will be standardized.

For my Dockerfile, I added the following:
```docker
FROM ubuntu:latest
WORKDIR ~/quickStart
COPY . .
RUN apt update -y
RUN apt install wget -y
RUN wget https://github.com/gohugoio/hugo/releases/download/v0.134.2/hugo_extended_0.134.2_linux-amd64.tar.gz && \
    tar -xvzf hugo_extended_0.134.2_linux-amd64.tar.gz && \
    chmod +x hugo && \
    mv hugo /usr/local/bin/hugo && \
    rm -f hugo_extended_0.134.2_linux-amd64.tar.gz
RUN hugo version && \
    hugo
VOLUME [ "/public" ]
```
My Dockerfile instructs Docker to use the latest [Ubuntu Base Image](https://hub.docker.com/_/ubuntu) from the Docker Hub for my builds. My builds will be completed in the `quickStart` directory; Docker copies my site project files into this location using the `COPY` directive. Once the files are copied, the `RUN` directives instruct Docker what to do to build the site:
1. Update the package index and install `wget`
2. Download, extract, and install Hugo; make Hugo executable; clean up the archives
3. Validate the installation, run the `hugo` command to build my site

The final `VOLUME` directive tells Docker to expose the resulting web pages that are generated in the `~/quickStart/public` directory of the container.

Since I didn't want to copy ALL files in my project directory, I configured a `.dockerignore` file with the following:
```bash
.gitignore
.gitmodules
.git
public
resources/_gen
```

To validate my configuration, I ran the following command which automatically uses the Dockerfile in the project directory to build the image and tags it using the name `hugo-release`:
```bash
sudo docker build -t hugo-release .
```
After that, I ran the following command to extract the `public` directory from my image:
```bash
docker run --rm hugo-release tar -cf - public | tar -xvf - -C $target_directory --strip-components=1
```
The command runs my image tagged with `hugo-release`, removes the container when done, archives my public direcory's contents, and extracts them to the `$target_dir` which is the `public_html` folder I created in my initial configuration.

## Automating the Build and Deploy Process
With Docker installed on my instance and a functional Dockerfile that allows me to standardize my build, the final task I needed to accomplish was to automate my site build and deployment. Since the build and deploy process is straight forward, I decided a simple shell script would suffice.

To write a script that will handle the build and deploy, I drew back on the steps I take to manually build and publish my site:
```bash
sudo docker build -t hugo-release . # Build the image that ultimately compiles my site
docker run --rm hugo-release tar -cf - public | tar -xvf - -C $target_directory --strip-components=1 # Run my image to compile my site and extract the files
rm -r $target_dir/* # Remove the outdated site files
cp -a $source_dir/. $target_dir/ # Load my new files
```

With all this in mind, I put together the baseline script:
```bash
# Pull the latest files from the Git remote repo
git pull
if sudo docker build -t hugo-release .; then
    # Create target directory if not exists
	mkdir -p $target_dir
    # Create a backup of the current site pages
	pushd $target_dir
	tar -czvf /var/www/html/redflowers.io/backups/site.$(date +%Y%m%d-%H%M%S).tar.gz .
	popd
	# Clear target directory
	sudo rm -fr $target_dir/*
	# Copy build to target directory
	sudo docker run --rm hugo-release tar -cf - public | sudo tar -xvf - -C $target_dir --strip-components=1
else
	echo "Docker build failed, aborting..."
	exit 1
fi
```
I also added some logic to protect myself from accidentally building/clearing the site files:
```bash
# Prompt user for confirmation
printf "This will delete the content of '$target_dir'. \n do you want to proceed? (y/n): "
read response

case "$response" in
	[Yy])
		echo "Proceeding..."
		;;
	[Nn])
		echo "Build aborted..."
		exit 0
		;;
	*)
		echo "Invalid input, aborting..."
		exit 1
		;;
esac
```
Lastly, I want to take an argument that determines where the `$target_dir` is by adding the following:
```bash
# Default value for target_directory
target_dir="./public"

while [ $# -gt 0 ]; do
	case "$1" in
		--target-dir | -t)
			shift
			target_dir="$1"
			;;
		--help | -h)
			echo "Usage: $0 [OPIONS]"
			echo "Options:"
			echo " --target-dir, -t Specify the target directory"
			echo " --help, -h       Display this help message"
			exit 0
			;;
		*)
			# Unknown flag
			echo "Unknown option: $1"
			exit 1
			;;
	esac
	shift
done
```
The final script:
```bash
#!/bin/sh
#
# Default value for target_directory
target_dir="./public"

while [ $# -gt 0 ]; do
	case "$1" in
		--target-dir | -t)
			shift
			target_dir="$1"
			;;
		--help | -h)
			echo "Usage: $0 [OPIONS]"
			echo "Options:"
			echo " --target-dir, -t Specify the target directory"
			echo " --help, -h       Display this help message"
			exit 0
			;;
		*)
			# Unknown flag
			echo "Unknown option: $1"
			exit 1
			;;
	esac
	shift
done

# Prompt user for confirmation
printf "This will delete the content of '$target_dir'. \n do you want to proceed? (y/n): "
read response

case "$response" in
	[Yy])
		echo "Proceeding..."
		;;
	[Nn])
		echo "Build aborted..."
		exit 0
		;;
	*)
		echo "Invalid input, aborting..."
		exit 1
		;;
esac

# Pull the latest files from the Git remote repo
git pull
if sudo docker build -t hugo-release .; then
    # Create target directory if not exists
	mkdir -p $target_dir
    # Create a backup of the current site pages
	pushd $target_dir
	tar -czvf /var/www/html/redflowers.io/backups/site.$(date +%Y%m%d-%H%M%S).tar.gz .
	popd
	# Clear target directory
	sudo rm -fr $target_dir/*
	# Copy build to target directory
	sudo docker run --rm hugo-release tar -cf - public | sudo tar -xvf - -C $target_dir --strip-components=1
else
	echo "Docker build failed, aborting..."
	exit 1
fi
```
Since I placed my script in the site project root so I can add it to my source control, I added the following line to my `.dockerignore` file so it is not copied to my image:
```docker
build_deploy.sh # Script that handles our build & deployment automation
```
Now when I want to update my site, I run my script from the project root directory with the following command:
```bash
./build_deploy.sh --target-dir /var/www/html/MyDomainName/public_html
```

## Resources
If you are interested in any of the resources I used, they were the following:
* [Docker](https://www.docker.com/) and the [Dockerfile Reference Page](https://docs.docker.com/reference/dockerfile/)
* [Step-by-Step Guide to Install Docker](https://medium.com/@srijaanaparthy/step-by-step-guide-to-install-docker-on-ubuntu-in-aws-a39746e5a63d) on EC2
* [AM Cloud Solution's Hosting Hugo blog post](https://amcloudsolutions.de/en/blog/hosting-hugo/)
* The latest [Ubuntu Base Image](https://hub.docker.com/_/ubuntu) from Docker Ub
