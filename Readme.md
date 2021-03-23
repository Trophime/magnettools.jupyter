# Running MagnetTools in Jupyter

* `docker build -f ./Dockerfile -t trophime/imagnettools:focal .`
* `docker run [--dns lncmi.dns] [-e DISPLAY=$DISPLAY] -v $PWD/tmp:/home/jovyan/work -v $PWD/tmp/data:/home/jovyan/data -p 8888:8888 trophime/imagnettools:focal`
* `docker run -it --rm --entrypoint "bash"  [--dns lncmi.dns] -v ${PWD}/tmp:/home/jovyan/work -v $PWD/tmp/data:/home/jovyan/data  -p 8888:8888  trophime/imagnettools:focal`

To get `lncmi-dns`:

```bash
nmcli dev show | grep 'IP4.DNS'
```

Start firefox:

* load page: `http://127.0.0.1:8888/?token=xxx`

[TIP]
On WSL2, to get X11 working:

* remenber to start MobaXterm prior to launch docker
* define DISPLAY env var: `export DISPLAY=$(awk '/nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null):0`
* add `-e DISPLAY=$DISPLAY` to the docker run arguments

This feature is needed to get file selection with tkinter in notebooks.

# Running as a Standalone webapp

* `docker build -f ./Dockerfile-app -t trophime/imagnettools:app .`
* `docker run [--dns lncmi.dns] -it --rm -p 80:8888 -v $PWD/tmp/data:/home/jovyan/work/data trophime/imagnettools:app`

# TODO


Notebook/Voila:
* add a dropdown menu to get d^nB/dx^n
* 2D view (?) for ideal Temperature
* ............... **real** ........................ (aka with real material properties instead of physical dat from dfile; this means to read the material prop from database or from json)
* 2D views for getdp output (later for feelpp)
* create graph plot for txt log files
* ..................... tdms files
* What about transient simulations with Sundials?

Notebook:
* add python package:

Here is a short snippet that should work in general:

```bash
# Install a conda package in the current Jupyter kernel
import sys
!conda install --yes --prefix {sys.prefix} numpy
```

If you used pip instead:

```bash
# Install a pip package in the current Jupyter kernel
import sys
!{sys.executable} -m pip install numpy
```

# References:

https://jakevdp.github.io/blog/2017/12/05/installing-python-packages-from-jupyter/

