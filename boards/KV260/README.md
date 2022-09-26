# Composable Pipeline Kria KV260 Vision Started Kit 

## Rebuild overlay

From your Linux terminal run:

```sh
make
```

Once the overlay generation is finished, the corresponding bitstream and hwh files are copied to the `overlay` folder.

To use relocatable bitstream libraries, do 
1) Make the shell compatible with the libraries
     make shell 
2) Build every function and write bitstream for PR 1
     make build_all_rm
3) Reloate libraties to every PR and copy them to a folder cv_dfx_3_pr_reloc
     make build_package



## Binary File License

Pre-compiled binary files are not provided under an OSI-approved open source license, because Xilinx is incapable of providing 100% corresponding sources.

Binary files are provided under the following [license](LICENSE)

------------------------------------------------------
<p align="center">Copyright&copy; 2021 Xilinx</p>
