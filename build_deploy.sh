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

if sudo docker build -t hugo-release .; then
	# Create target directory if not exists
	mkdir -p $target_dir
	# Clear target directory
	rm -r $target_dir/*
	# Copy build to target directory
	sudo docker run --rm hugo-release tar -cf - public | tar -xvf - -C $target_dir --strip-components=1
else
	echo "Docker build failed, aborting..."
	exit 1
fi
