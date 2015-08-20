# Use [tugboat-py](https://github.com/metocean/tugboat-py) instead - it's based on the docker compose codebase and better supported

# Tugboat

Manage groups of dockers.

Similar to [docker compose](https://docs.docker.com/compose/) but with support for multiple .yml files and a friendlier syntax.

[![NPM version](https://badge.fury.io/js/tugboat.svg)](http://badge.fury.io/js/tugboat)

## Install

To use on the command line

```sh
npm install -g tugboat
```

To use as an API

```sh
npm install tugboat
```


## Usage

```
  Usage: tug command parameters
         tug option

  Common:

    ps          List all running and available groups
    up          Update and run services
    down        Stop services
    diff        Describe the changes needed to update

  Management:

    rm          Delete services
    cull        Stop and delete services
    recreate    Stop, delete, then run services
    kill        Gracefully terminate services
    build       Build services
    rebuild     Build services from scratch
    logs        Display group logs
    exec        Run a command inside a service

  Options:

    -h          Display this usage information
    -v          Display the version number
```

## Examples

In the test.yml file:

```yml
volumes:
- config:/config

importantping:
  image: ubuntu
  dns: 8.8.8.8
  command: ping google.com
```

Running `tug up test` will create a container called `test_importantping_1`.  Additional `tug up test` commands will test differences to the yml file and only restart the container if changes are detected.

Global options (`volumes` in the above example) are applied to all docker services.

The yml format supports most options from the [docker compose yml format](https://docs.docker.com/compose/yml/), and a few more from the [docker cli](https://docs.docker.com/reference/run/):


Option | Available globally
------ | ------------------
add_hosts | ✔
build | ✘
cap_add | ✔
cap_drop | ✔
command | ✘
dns | ✔
domainname | ✔
env_file | ✔
entrypoint | ✘
environment | ✔
expose | ✔
hostname | ✘
image | ✘
links | ✔
mem_limit | ✘
net | ✔
notes | ✔
ports | ✔
privileged | ✔
restart | ✔
scripts | ✔
user | ✔
volumes | ✔
working_dir | ✘


If there's an important docker compose option that isn't supported by tugboat, raise an issue.
