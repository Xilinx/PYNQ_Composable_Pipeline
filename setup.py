# Copyright (C) 2022 Xilinx, Inc
#
# SPDX-License-Identifier: BSD-3-Clause


__author__ = "Mario Ruiz"
__copyright__ = "Copyright 2022, Xilinx"
__email__ = "pynq_support@xilinx.com"


from setuptools import setup, find_packages
import os
import shutil
import re
import tempfile
import urllib.request
import hashlib
from pynqutils.setup_utils import build_py


# global variables
module_name = "pynq_composable"

board = os.environ.get("BOARD")
board_folder = "boards/{}".format(board)
notebooks_dir = os.environ.get("PYNQ_JUPYTER_NOTEBOOKS")
overlay_dest = "{}/".format(module_name)
data_files = []
cwd = os.getcwd()


# parse version number
def find_version(file_path):
    with open(file_path, "r") as fp:
        version_file = fp.read()
        version_match = re.search(r"^__version__ = ['\"]([^'\"]*)['\"]",
                                  version_file, re.M)
    if version_match:
        return version_match.group(1)
    raise NameError("Version string must be defined in {}.".format(file_path))


# extend package
def extend_package(path):
    if os.path.isdir(path):
        data_files.extend(
            [os.path.join("..", root, f)
             for root, _, files in os.walk(path) for f in files]
        )
    elif os.path.isfile(path):
        data_files.append(os.path.join("..", path))


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
                with open(os.sep.join([dirpath, filename]), 'r') as file :
                    filedata = file.read()

                filedata = filedata.replace("HDMI", "DisplayPort")
                filedata = filedata.replace("VideoStream(ol, source=VSource.MIPI)",
                    "VideoStream(ol, source=VSource.MIPI, sink=VSink.DP)")
                filedata = filedata.replace("VideoStream(ol, source=VSource.OpenCV)",
                    "VideoStream(ol, source=VSource.OpenCV, sink=VSink.DP)")
                filedata = filedata.replace("VideoStream(ol)",
                    "VideoStream(ol, source=VSource.OpenCV, sink=VSink.DP)")
                filedata = filedata.replace("cpipe.hdmi_source_in",
                                            "cpipe.ps_video_in")
                filedata = filedata.replace("cpipe.hdmi_source_out",
                                            "cpipe.ps_video_out")

                with open(os.sep.join([dirpath, filename]), 'w') as file:
                    file.write(filedata)


overlay = {
    "Pynq-Z2": {
                    "url": "https://www.xilinx.com/bin/public/openDownload?filename=composable-video-pipeline-Pynq-Z2-v1_0_0.zip",
                    "md5sum": "45421bd8844749a219fd7147af17e9d6",
                    "format": "zip"
                },
    "Pynq-ZU": {
                    "url": "https://www.xilinx.com/bin/public/openDownload?filename=composable-video-pipeline-Pynq-ZU-v1_0_0.zip",
                    "md5sum": "0ad2da3dfda6d3392d4845f18404dc3c",
                    "format": "zip"
                },
    "KV260": {
                    "url": "https://www.xilinx.com/bin/public/openDownload?filename=composable-video-pipeline-KV260-v1_0_0.zip",
                    "md5sum": "262de1a9614d9c4018cdb982e3023531",
                    "format": "zip"
                }
}

"""PYNQ-Z1 is supported with the same overlay as PYNQ-Z2"""
overlay["Pynq-Z1"] = overlay["Pynq-Z2"]

def download_overlay(board, overlay_dest):
    """Download precompiled overlay from the Internet"""
    if board not in overlay.keys():
        return

    download_link = overlay[board]["url"]
    md5sum = overlay[board].get("md5sum")
    archive_format = overlay[board].get("format")
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

    shutil.unpack_archive(tmp_file, overlay_dest, archive_format)

if board:
    copy_notebooks(board_folder, module_name)
    download_overlay(board, overlay_dest)
extend_package(module_name)
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
        "pynq>=2.7.0",
        "graphviz>=0.20",
        "pytest-dependency>=0.5.1",
        "pytest-timeout>=2.1.0",
        "deepdiff>=5.8.1"
    ],
    entry_points=entry_points,
    cmdclass={"build_py": build_py},
    platforms=[board]
)
