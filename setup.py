# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause


__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2022, Xilinx"
__email__ = "pynq_support@xilinx.com"


import hashlib
import json
import os
from pynqutils.setup_utils import build_py, find_version, extend_package
from setuptools import setup, find_packages
import shutil
import tempfile
import urllib.request


module_name = "pynq_composable"
board = os.environ.get("BOARD")
board_folder = "boards/{}".format(board)
notebooks_dir = os.environ.get("PYNQ_JUPYTER_NOTEBOOKS")
overlay_dest = "{}/".format(module_name)
data_files = []
cwd = os.getcwd()


def copy_notebooks(board_folder, module_name):
    """Copy board specific notebooks"""

    src_dir = "{}/notebooks".format(board_folder)
    if not os.path.exists(src_dir):
        return

    for (dirpath, dirnames, filenames) in os.walk(src_dir):
        for filename in filenames:
            if filename.endswith(".ipynb"):
                src = os.sep.join([dirpath, filename])
                dst = src.replace(board_folder, module_name)
                shutil.copy(src, dst)


def update_notebooks_display_port(module_name):
    """Update notebooks for KV260

    Search for HDMI and replace it with Display Port.
    Make sure sink is set to VSink.DP

    """
    if board != "KV260":
        return
    for (dirpath, dirnames, filenames) in os.walk(module_name):
        for filename in filenames:
            if filename.endswith(".ipynb"):
                with open(os.sep.join([dirpath, filename]), 'r') as file:
                    filedata = file.read()

                filedata = filedata.replace("HDMI", "DisplayPort")
                filedata = filedata.replace(
                    "VideoStream(ol, source=VSource.MIPI)",
                    "VideoStream(ol, source=VSource.MIPI, sink=VSink.DP)")
                filedata = filedata.replace(
                    "VideoStream(ol, source=VSource.OpenCV)",
                    "VideoStream(ol, source=VSource.OpenCV, sink=VSink.DP)")
                filedata = filedata.replace(
                    "VideoStream(ol)",
                    "VideoStream(ol, source=VSource.OpenCV, sink=VSink.DP)")
                filedata = filedata.replace("cpipe.hdmi_source_in",
                                            "cpipe.ps_video_in")
                filedata = filedata.replace("cpipe.hdmi_source_out",
                                            "cpipe.ps_video_out")

                with open(os.sep.join([dirpath, filename]), 'w') as file:
                    file.write(filedata)


with open(module_name + '/overlay.link') as file:
    overlay = json.load(file)


def download_overlay(board, overlay_dest):
    """Download precompiled overlay from the Internet"""
    if board not in overlay.keys():
        return

    download_link = overlay[board]["url"]
    md5sum = overlay[board].get("md5sum")
    tmp_file = tempfile.mkstemp()[1]

    with urllib.request.urlopen(download_link) as response, \
            open(tmp_file, "wb") as out_file:
        data = response.read()
        out_file.write(data)
    if md5sum:
        file_md5sum = hashlib.md5()
        with open(tmp_file, "rb") as out_file:
            for chunk in iter(lambda: out_file.read(4096), b""):
                file_md5sum.update(chunk)
        if md5sum != file_md5sum.hexdigest():
            os.remove(tmp_file)
            raise ImportWarning("Incorrect checksum for file. The composable "
                                "overlay will not be delivered")

    shutil.unpack_archive(tmp_file, overlay_dest, "zip")


if board:
    copy_notebooks(board_folder, module_name)
    download_overlay(board, overlay_dest + '/overlay/')


extend_package(module_name, data_files)
update_notebooks_display_port(module_name + '/notebooks/')
pkg_version = find_version("{}/__init__.py".format(module_name))


# Declare the overlay entry points only if the overlay can be downloaded
entry_points = {
    "pynq.notebooks": [
        "{} = {}.notebooks".format(module_name, module_name)
    ]
}
if board in overlay.keys():
    entry_points['pynq.overlays'] =\
        ["{} = {}.overlay".format(module_name, module_name)]

setup(
    name=module_name,
    version=pkg_version,
    description="Composable Video Pipeline",
    author="Xilinx PYNQ Development Team",
    author_email="pynq_support@xilinx.com",
    url="https://github.com/Xilinx/PYNQ_Composable_Pipeline",
    license="BSD 3-Clause License",
    packages=find_packages(),
    package_data={
        "": data_files,
    },
    python_requires=">=3.8.0",
    install_requires=[
        "pynq>=3.0.1",
        "graphviz>=0.20",
        "pytest-dependency>=0.5.1",
        "pytest-timeout>=2.1.0",
        "deepdiff>=5.8.1",
        "coverage>=6.4.4"
    ],
    entry_points=entry_points,
    cmdclass={"build_py": build_py},
    platforms=[board]
)
