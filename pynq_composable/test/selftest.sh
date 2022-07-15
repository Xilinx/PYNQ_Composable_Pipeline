#!/bin/bash

coverage run --source ../ -m pytest test_composable.py -vv && coverage report --show-missing