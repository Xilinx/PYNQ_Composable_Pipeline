#!/bin/bash

coverage run --source ../ -m pytest . -vv && coverage report --show-missing