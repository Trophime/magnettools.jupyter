# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

LABEL maintainer="Christophe Trophime <christophe.trophime@lncmi.cnrs.fr>"

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# This Dockerfile adds a non-root user with sudo access. Use the "remoteUser"
# property in devcontainer.json to use it. On Linux, the container user's GID/UIDs
# will be updated to match your local UID/GID (when using the dockerFile property).
# See https://aka.ms/vscode-remote/containers/non-root-user for details.
ARG USERNAME=${NB_USER}
ARG USER_UID=${NB_UID}
ARG USER_GID=${NB_GID}

USER root

ENV LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8 \
	LC_ALL=C.UTF-8

RUN apt-get -qq update && \
    apt-get -y install debian-keyring lsb-release && \
    cp /usr/share/keyrings/debian-maintainers.gpg /etc/apt/trusted.gpg.d && \
    echo "*** install prerequisites for MagnetTools ***" && \
    echo "deb http://euler.GRENOBLE.LNCMI.LOCAL/~trophime/debian/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/lncmi.list && \
    apt-get update

# Configure apt and install packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
    # \
    # Verify git, process tools, lsb-release (useful for CLI installs) installed\
    && apt-get -y install git iproute2 procps lsb-release \
    #\
    # Install C++ tools\
    && apt-get -y install build-essential python3-minimal libpython3.8 \
    && apt-get -y install cmake clang g++ gfortran git \
    && apt-get -y install cmake git clang g++ gfortran \
    && apt-get -y --no-install-recommends install libyaml-cpp-dev libjson-spirit-dev libgsl-dev libfreesteam-dev \
         libpopt-dev zlib1g-dev libeigen3-dev fadbad++ libgnuplot-iostream-dev \
         libsphere-dev libsundials-dev libmatheval-dev \
    # ffmpeg for matplotlib anim & dvipng+cm-super for latex labels
    && apt-get update \
    && apt-get install -y --no-install-recommends ffmpeg dvipng cm-super \
    #\
    # Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.\
    # && groupadd --gid $USER_GID $USERNAME \
    # && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support for the non-root user
    && apt-get install -y sudo \
    #&& if [ "$(lsb_release -cs)" = "focal" ]; then echo "Set disable_coredump false" > /etc/sudo.conf; fi \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # add github ssh key
    && mkdir -p ~${USERNAME}/.ssh/ \
    && ssh-keyscan github.com >> ~${USERNAME}/.ssh/known_hosts \
    && chown -R ${USERNAME}.$USER_GID ~${USERNAME}/.ssh \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3 packages
RUN mamba install --quiet --yes \
    'boa' \
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
    rm -rf "/home/${USERNAME}/.cache/yarn" && \
    rm -rf "/home/${USERNAME}/.node-gyp" && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${USERNAME}"

# Install facets which does not have a pip or conda package at the moment
WORKDIR /tmp
RUN git clone https://github.com/PAIR-code/facets.git && \
    jupyter nbextension install facets/facets-dist/ --sys-prefix && \
    rm -rf /tmp/facets && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${USERNAME}"

RUN apt-get update \
    && apt-get -y install python3-magnetsetup python3-magnetgeo python3-chevron \
    && echo "CONDA_DIR=${CONDA_DIR}" \
    && echo -n "Finding python version:" \
    && PYVER=$(find ${CONDA_DIR}/lib -maxdepth 1 -name python\* | perl -p -e "s|${CONDA_DIR}/lib/python||") \
    && echo " ${PYVER}" \
    && ln -s /usr/lib/python3/dist-packages/python_magnetsetup ${CONDA_DIR}/lib/python${PYVER}/site-packages/python_magnetsetup \
    && ln -s /usr/lib/python3/dist-packages/python_magnetgeo ${CONDA_DIR}/lib/python${PYVER}/site-packages/python_magnetgeo \
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME="/home/${USERNAME}/.cache/"

RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions "/home/${USERNAME}"

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog


USER $USER_UID
WORKDIR $HOME
