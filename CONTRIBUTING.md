# Contributing to the PYNQ Composable Overlays

We welcome contributions to the PYNQ Composable Overlays! 

You can contribute in a variety of ways. You can report bugs and feature requests using [GitHub Issues](https://github.com/Xilinx/PYNQ_Composable_Pipeline/issues). You can send patches which add new features bug fixes. You can also contribute to the [documentation](https://pynq-composable.readthedocs.io/en/latest/).

## Reporting Issues

When reporting issues on GitHub, please include the following.

Use [snippets](https://docs.github.com/en/github/writing-on-github/creating-and-highlighting-code-blocks) instead of images when reporting these, it is much easier to track the problem.

### Build Issues

1. OS version `lsb_release -a`
1. Vivado version `vivado -version`

### Run Time Issues

1. Board
1. PYNQ (or Ubuntu) SD Card Version
1. pynq version `pynq version`

## Contributing Code

Please use [GitHub Pull Requests (PR)](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request-from-a-fork) for sending code contributions. When sending code [sign your](#sign-your-work) work as described below. Be sure to use the same [license](LICENSE) for your contributions as the current license of this repository.

### Branches

`main` is the latest stable version, PRs will not be accepted into this branch.

To contribute code or documentation, please Pull Request against the branch that has `-dev` postfix.

## Sign Your Work

Please use the *Signed-off-by* line at the end of your patch which indicates that you accept the Developer Certificate of Origin (DCO) defined by https://developercertificate.org/ reproduced below:

```
  Developer Certificate of Origin
  Version 1.1

  Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
  1 Letterman Drive
  Suite D4700
  San Francisco, CA, 94129

  Everyone is permitted to copy and distribute verbatim copies of this
  license document, but changing it is not allowed.


  Developer's Certificate of Origin 1.1

  By making a contribution to this project, I certify that:

  (a) The contribution was created in whole or in part by me and I
      have the right to submit it under the open source license
      indicated in the file; or

  (b) The contribution is based upon previous work that, to the best
      of my knowledge, is covered under an appropriate open source
      license and I have the right under that license to submit that
      work with modifications, whether created in whole or in part
      by me, under the same open source license (unless I am
      permitted to submit under a different license), as indicated
      in the file; or

  (c) The contribution was provided directly to me by some other
      person who certified (a), (b) or (c) and I have not modified
      it.

  (d) I understand and agree that this project and the contribution
      are public and that a record of the contribution (including all
      personal information I submit with it, including my sign-off) is
      maintained indefinitely and may be redistributed consistent with
      this project or the open source license(s) involved.
```

Here is an example Signed-off-by line which indicates that the contributor accepts DCO:

```
  This is my commit message

  Signed-off-by: Jane Doe <jane.doe@example.com>
```


## Contribution Review

If any additional fixes or modifications are necessary, we may provide feedback to guide 
you. When accepted, your pull request will be merged to the repository.

------------------------------------------------------
<p align="center">Copyright&copy; 2021 Xilinx</p>