#!/bin/bash


die(){
    echo >&2 "$@"
    exit 1
}

IN_DIR=$1
mkdir nifti
dcm2niix -o /nifti $IN_DIR

shift

IN_FILE=$(ls /nifti/*.nii* | head -1)
[[ -f ${IN_FILE} ]] || die "Did not find nii file in ${IN_DIR}"

echo IN_FILE=${IN_FILE}

PID=$$

ATLAS_IMAGE=/opt/atlases/mni_icbm152_t1_tal_nlin_sym_09a.nii.gz
ATLAS_MASK=/opt/atlases/mni_icbm152_t1_tal_nlin_sym_09a_face_mask.nii.gz
echo ATLAS_IMAGE=${ATLAS_IMAGE}
echo ATLAS_MASK=${ATLAS_MASK}

reg_aladin -ref ${IN_FILE} \
           -flo ${ATLAS_IMAGE}\
           -aff /tmp/${PID}_mat.txt \
           -lp 2 || die "Registration failed"
reg_resample -ref ${IN_FILE} \
             -flo ${ATLAS_MASK} \
             -trans /tmp/${PID}_mat.txt \
             -inter 0 \
             -res /tmp/${PID}_mask.nii.gz || die "Propagation failed"
reg_tools -in ${IN_FILE} \
          -float \
          -out /tmp/${PID}_input_float.nii.gz  || die "Input conversion failed"
reg_tools -in /tmp/${PID}_input_float.nii.gz \
          -smoG 5 5 5 \
          -out /tmp/${PID}_smoothed.nii.gz || die "Input smoothing failed"
reg_tools -in /tmp/${PID}_smoothed.nii.gz \
          -mul /tmp/${PID}_mask.nii.gz \
          -out /tmp/${PID}_out.nii.gz || die "Face masking failed"
reg_tools -in /tmp/${PID}_mask.nii.gz \
          -mul -1 \
          -out /tmp/${PID}_invert.nii.gz || die "Invert mask part 1 failed"
reg_tools -in /tmp/${PID}_invert.nii.gz \
          -add 1 \
          -out /tmp/${PID}_invert.nii.gz || die "Invert mask part 2 failed"
reg_tools -in ${IN_FILE} \
          -mul /tmp/${PID}_invert.nii.gz \
          -out /tmp/${PID}_smoothed.nii.gz || die "Face extraction failed"
reg_tools -in /tmp/${PID}_out.nii.gz \
          -add /tmp/${PID}_smoothed.nii.gz \
          -out /output/${PID}_out.nii.gz || die "Face composition failed"

