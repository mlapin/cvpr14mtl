Multitask Representation Learning
=========

This code was used to produce results reported in the following paper:

Maksim Lapin, Bernt Schiele and Matthias Hein  
[Scalable Multitask Representation Learning for Scene Classification](http://www.d2.mpi-inf.mpg.de/content/scalable-multitask-representation-learning-scene-classification-0)  
In _IEEE Conference on Computer Vision and Pattern Recognition (CVPR)_, 2014


The software was tested on Debian GNU/Linux 7.4 (wheezy)
using MATLAB R2013a and GCC 4.4.


Getting started
---

```
git clone https://github.com/mlapin/cvpr14mtl.git
```

At MATLAB prompt:
```
showresults
```


Playing with the precomputed kernels
---

Download the precomputed kernels:
```
cd matlab && make playkernels
```

At MATLAB prompt:
```
playground
```
You may need to recompile the STL-SDCA and MTL-SDCA solvers,
see below for instructions.

To download more kernels (excluding the ones from Xiao et al.), run:
```
cd matlab && make allkernels
```


Running experiments
---

##### STL-SDCA and MTL-SDCA solvers (mex code)
```
cd mtlsdca && make clean && make
```
If MATLAB is not found, edit the `Makefile` and set the path manually,  
e.g. `MATLAB_PATH = /usr/lib/matlab-8.1`

If Intel MKL is installed, specify the corresponding path in `INTEL_MKL_PATH`;  
otherwise, MATLAB BLAS will be used.

To disable verbose output from the solvers,
comment out the following line in the Makefile and recompile:
`STD_CXXFLAGS += -DVERBOSE`


##### USPS/MNIST experiments
```
cd usps && make
```
This will compile MATLAB code `experiments.m`
and create a text file `cmd_experiments.txt`
with commands that can be executed in parallel.
MCR environment needs to be set up to run the commands,
see `run_experiments.sh` for details.
To learn more about working with the compiled MATLAB code, visit  
http://www.mathworks.com/help/compiler/working-with-the-mcr.html


##### SUN397 experiments
First, create the 10 splits.
Go to `matlab/splits` and run at MATLAB prompt:
```
splits
```

Next, have a look at the `Makefile`:
```
cd matlab && make
```
This will show a list of available make targets.
*Note*: you **must** modify the `Makefile`.
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

*Note*: all results (precomputed kernel matrices, trained models,
test scores, etc.) will be stored in `matlab/experiments`
and will require disk space on the order of 500-700GB.
By default, caching of image descriptors (Fisher Vector) is disabled
(`doNotCacheDescriptors = true` in `matlab/recognition/traintest.m`)
and only the kernel matrices are saved to disk.
Otherwise, the disk space requirements increase to up to 3-4TB.
