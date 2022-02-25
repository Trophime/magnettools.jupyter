# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Christophe Trophime <christophe.trophime@lncmi.cnrs.fr>"

ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"

USER root

# to help debug but shall not be present in prod
RUN echo $NB_USER ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$NB_USER && \
    chmod 0440 /etc/sudoers.d/$NB_USER

# Seup demo environment variables
ENV LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8 \
	LC_ALL=C.UTF-8

RUN apt-get -qq update && \
    apt-get -y install build-essential debian-keyring lsb-release && \
    cp /usr/share/keyrings/debian-maintainers.gpg /etc/apt/trusted.gpg.d

RUN echo "lsb_release=$(lsb_release -cs)"
RUN echo "*** install prerequisites for MagnetTools ***" && \
    echo "deb http://euler.GRENOBLE.LNCMI.LOCAL/~trophime/debian/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/lncmi.list && \
    echo "deb-src http://euler.GRENOBLE.LNCMI.LOCAL/~trophime/debian/ $(lsb_release -cs) main" >> /etc/apt/sources.list.d/lncmi.list && \
    apt-get -qq update && \
    apt-get -y install cmake clang g++ gfortran git && \
    apt-get -y --no-install-recommends install libyaml-cpp-dev libjson-spirit-dev libgsl-dev libfreesteam-dev \
         libpopt-dev zlib1g-dev libeigen3-dev fadbad++ libgnuplot-iostream-dev \
         libsphere-dev libsundials-dev libmatheval-dev
    

# ffmpeg for matplotlib anim & dvipng+cm-super for latex labels
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg dvipng cm-super && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python 3 packages
RUN mamba install --quiet --yes \
    'boa' \
    'swig' \
    'conda-forge::python-decouple' \
    'requests' \
    'beautifulsoup4' \
    'conda-forge::blas=*=openblas' \
    'bokeh' \
    'bottleneck' \
    'cloudpickle' \
    'cython' \
    'dask' \
    'dill' \
    'h5py' \
    'ipywidgets' \
    'ipympl'\
    'matplotlib-base' \
    'conda-forge::mplcursors' \
    'numba' \
    'numexpr' \
    'pandas' \
    'conda-forge::pint' \
    'conda-forge::pint-pandas' \
    'panel' \
    'hvplot' \
    'patsy' \
    'protobuf' \
    'pytables' \
    'scikit-image' \
    'scikit-learn' \
    'scipy' \
    'seaborn' \
    'sqlalchemy' \
    'statsmodels' \
    'sympy' \
    'vincent' \
    'widgetsnbextension' \
    'xlrd' \
    'conda-forge::ipyfilechooser' \
    'conda-forge::voila' \
    'bqplot' \
    'tabulate' \
    'mplcursors' \
    'chevron' \
    'pythreejs' \
    'conda-forge::pythonocc-core=7.5.1' \
    'conda-forge::occt=7.5.1' \
    && \
    mamba clean --all -f -y && \
    # Activate ipywidgets extension in the environment that runs the notebook server
    jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
    # # Also activate ipywidgets extension for JupyterLab
    # # Check this URL for most recent compatibilities
    # # https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
    # jupyter labextension install @jupyter-widgets/jupyterlab-manager@^2.0.0 --no-build && \
    # jupyter labextension install @bokeh/jupyter_bokeh@^2.0.0 --no-build && \
    # jupyter labextension install jupyter-matplotlib@^0.7.2 --no-build && \
    jupyter lab build -y && \
    jupyter lab clean -y && \
    npm cache clean --force && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

# Install properly MagnetTools into conda env
    
# Install facets which does not have a pip or conda package at the moment
WORKDIR /tmp
RUN git clone https://github.com/PAIR-code/facets.git && \
    jupyter nbextension install facets/facets-dist/ --sys-prefix && \
    rm -rf /tmp/facets && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

USER $NB_UID
WORKDIR /tmp
RUN git clone https://github.com/Trophime/magnetsetup.conda.git \
    && git clone https://github.com/Trophime/magnetgeo.conda.git \
    && git clone https://github.com/Trophime/magnettools.conda.git \
    && cd magnettools.conda && ls \
    && echo "get magnettools source" \
    && sudo apt-get update \
    && apt-get source magnettools \
    && cd .. \
    && sudo apt-get autoremove -y \
    && sudo apt-get clean -y \
    && sudo rm -rf /var/lib/apt/lists/*

USER root
RUN cd magnettools.conda \
    && boa build . \
    && mamba install --quiet --yes magnettools --use-local \
    && cd ../magnetsetup.conda \
    && boa build . \
    && mamba install --quiet --yes magnetsetup --use-local \
    && cd ../magnetgeo.conda \
    && boa build . \
    && mamba install --quiet --yes magnetgeo --use-local \
    && rm -rf tmp/magnettools.conda \
    && rm -rf /home/${NB_USER}/magnettools*


# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME="/home/${NB_USER}/.cache/"

RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions "/home/${NB_USER}"

USER $NB_UID
WORKDIR $HOME
ENV LD_LIBRARY_PATH=/opt/conda/lib/MagnetTools:$LD_LIBRARY_PATH
