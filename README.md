# Tugboat

Manage groups of dockers.

Similar to [fig](http://www.fig.sh/) but with support for multiple .yml files.

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

  Common:

    ps          List all running and available groups
    up          Update and run services
    down        Stop services
    diff        Describe the changes needed to update

  Management:

    cull        Terminate, stop and remove services
    rm          Delete services
    kill        Gracefully terminate services
    build       Build services
    rebuild     Build services from scratch
```

## Examples

In the test.yml file:

```yml
importantping:
  image: ubuntu
  dns: 8.8.8.8
  volumes:
  - share:/share
  command: ping google.com
```

Running `tug up test` will create a container called `test_importantping_`
. Any changes to the file will be compared to running continers. Additional `tug up test` commands will test differences and only restart the container if changes are detected.

The yml format is identical to the [fig.yml format](http://www.fig.sh/yml.html).