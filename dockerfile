FROM neurodebian:nd16.04
RUN apt-get -y update

RUN apt-get -y install dcm2niix \
        make \
        cmake \
        gcc \
        g++ \
        wget \
        zip \
        gzip \
        git


# Download NiftyReg
RUN cd /opt && \
    git clone https://github.com/KCL-BMEIS/niftyreg.git niftyreg

# Install NiftyReg
RUN cd /opt/niftyreg && \
    mkdir build && \
    cd build && \
    cmake \
        -D CMAKE_BUILD_TYPE=Release \
        -D CMAKE_C_COMPILER=gcc \
        -D CMAKE_CXX_COMPILER=g++ \
        -D CMAKE_MAKE_PROGRAM=make \
        -D USE_OPENMP=OFF \
        /opt/niftyreg && \
    make && \
    make install

# Download atlases
RUN mkdir /opt/atlases && \
    cd /tmp && \
    wget http://www.bic.mni.mcgill.ca/~vfonov/icbm/2009/mni_icbm152_nlin_sym_09a_nifti.zip && \
    ls && \
    unzip mni_icbm152_nlin_sym_09a_nifti.zip && \
    ls && \
    gzip mni_icbm152_nlin_sym_09a/mni_icbm152_t1_tal_nlin_sym_09a.nii  && \
    gzip mni_icbm152_nlin_sym_09a/mni_icbm152_t1_tal_nlin_sym_09a_face_mask.nii && \
    mv mni_icbm152_nlin_sym_09a/*.nii.gz /opt/atlases

# Clean non-required packages
RUN rm -r /opt/niftyreg && \
    apt-get -y  --allow-remove-essential remove \
        make \
        cmake \
        wget \
        zip \
        gzip \
        git \
    && \
    rm -rf /tmp/* /var/tmp/*

# Copy the required script to run the defacing

ADD run.sh /usr/local/bin
RUN chmod 775 /usr/local/bin/run.sh

LABEL org.nrg.commands="[{\"name\": \"AI4VBH-deface (based on NiftyReg)\", \"label\": \"AI4VBH-deface (based on NiftyReg)\", \"description\": \"Module to deface head image based on segmentation propagation and image smoothing.\", \"version\": \"1.0\", \"schema-version\": \"1.0\", \"type\": \"docker\", \"image\": \"xnat/ai4vbh_defacing:2.0\", \"info-url\": \"None\", \"command-line\": \"run.sh /input\", \"workdir\": \"/output\", \"mounts\": [{\"name\": \"input-scan-mount\", \"writable\": \"false\", \"path\": \"/input\"}, {\"name\": \"output-mount\", \"writable\": \"true\", \"path\": \"/output\"}], \"outputs\": [{\"name\": \"defaced-output\", \"description\": \"The input image has been defaced\", \"required\": true, \"mount\": \"output-mount\"}], \"xnat\": [{\"name\": \"AI4VBH-defacing\", \"description\": \"Run the defacing processing from a Session\", \"contexts\": [\"xnat:imageSessionData\"], \"external-inputs\": [{\"name\": \"session\", \"description\": \"Input session\", \"type\": \"Session\", \"required\": true}], \"derived-inputs\": [{\"name\": \"input-scan\", \"description\": \"The input scan, to be defaced\", \"type\": \"Scan\", \"derived-from-wrapper-input\": \"session\", \"matcher\": \"'DICOM' in @.resources[*].label\"}, {\"name\": \"input-scan-dicom\", \"description\": \"The input scan's dicom resource\", \"type\": \"Resource\", \"derived-from-wrapper-input\": \"input-scan\", \"provides-files-for-command-mount\": \"input-scan-mount\", \"matcher\": \"@.label == 'DICOM'\"}, {\"name\": \"input-scan-id\", \"description\": \"The input scan's id\", \"type\": \"string\", \"derived-from-wrapper-input\": \"input-scan\", \"derived-from-xnat-object-property\": \"id\"}], \"output-handlers\": [{\"name\": \"defaced\", \"type\": \"Resource\", \"accepts-command-output\": \"defaced-output\", \"as-a-child-of-wrapper-input\": \"input-scan\", \"label\": \"DEFACED_#input-scan-id#\"}]}]}]"

