Multitask Learning for Scene Classification
=========

This is the source code used to produce results reported in the paper:

Maksim Lapin, Bernt Schiele and Matthias Hein
**Scalable Multitask Representation Learning for Scene Classification**
In _IEEE Conference on Computer Vision and Pattern Recognition (CVPR)_, 2014

Feel free to send your questions to:
[Maksim Lapin](www.mpi-inf.mpg.de/~mlapin/) (mlapin@mpi-inf.mpg.de)

The software was tested on Debian GNU/Linux 7.4 (wheezy)
using MATLAB version R2013a and GCC version 4.4.


Getting Started
---

```
git clone https://github.com/mlapin/cvpr14mtl.git
```

At MATLAB prompt:
```
showresults
```


Running experiments
---

##### Compile mex code (STL-SDCA and MTL-SDCA solvers)
```
cd mtlsdca
make
```
If the path to MATLAB is not resolved automatically, edit the `Makefile`
to set it manually, e.g. `MATLAB_PATH = /usr/lib/matlab-8.1`

##### USPS/MNIST experiments
```
cd usps
make
```
This will compile MATLAB code `experiments.m`
and create a text file `cmd_experiments.txt`
with commands that can be executed in parallel.
MCR environment needs to be set up to run the commands,
see `run_experiments.sh` for details.

##### SUN397 experiments
First, create the 10 splits.
Go to `matlab/splits` and run at MATLAB prompt:
```
splits
```

Next, have a look at the `Makefile`:
```
cd matlab
make
```
This will show a list of available make targets.

Note: you **must** modify the `Makefile`.
At the very minimum, you must specify:
  - `SUN397 = ` the path to the downloaded SUN397 dataset;
  - `SUN397R100K = ` the path to a directory where the processed (resized)
  images will be stored;
  - arguments to the `make/make_cmd_[mtl]experiments.sh` scripts,
  see `ex` and `exmtl` make targets.

To resize images to at most 100K pixels, run
```
make r100k
```

To run single task learning (STL) experiments, use
```
make ex
```
This will compile MATLAB code and create a number of text files with commands
that can be executed in parallel. As with the USPS/MNIST experiments,
MCR environment needs to be set up to run the commands.

Similarly, to run multitask learning (MTL) experiments, use
```
make exmtl
```

Note: all results will be stored in `matlab/experiments`
and will require disk space on the order of 500-700GB.
By default, caching of image descriptors (Fisher Vector) is disabled
(`doNotCacheDescriptors = true` in `matlab/recognition/traintest.m`)
and only the kernel matrices are saved to disk.
Otherwise, the disk space requirements increase to up to 3-4TB.
