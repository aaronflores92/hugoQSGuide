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
