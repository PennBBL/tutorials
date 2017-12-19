#############################################
#  Lauren Beard | fsGLM Tutorial | 20171120 #
#############################################

#! /bin/bash

# Set directories
data=/data/joy/BBL/tutorials/exampleData/fsGLM/n13_fsGLM_demos.csv
scriptsdir=/data/joy/BBL/tutorials/code/tutorials/fsGLM
export SUBJECTS_DIR=/data/joy/BBL/studies/pnc/processedData/structural/freesurfer53
# place where concatenated files will be stored

# TUTORIAL USER EDIT THIS PATH
homedir=/path/to/your/directory

# place where output is stored
outdir=$homedir
mkdir $homedir/designs
logdir=$homedir/logs
rm -f $logdir/*


# Set parameters
meas=area
fwhm=20
template=fsaverage5
hemi=lh


# Create model
# for lm you have to write all terms of interaction, e.g. age + sex + age:sex
# used as argument for R script. since it's a string it must be in quotes (twice).
lm='"~ ZAge + ZAgesq + Zsex + ZTBV"' 


# Get number and order of subjects
n=$(cat $data | wc -l)
n=$(echo "$n - 1" | bc)


# Set model name
name=$(echo $lm | sed "s/~//g" | sed "s/\"//g" | sed "s/ //g" | sed "s/+/_/g" | sed "s/:/BY/g" | sed "s/1/mean/g" )
echo $name
model=n${n}.$meas.$name.fwhm$fwhm.$template


## Set where design files are stored
mkdir $outdir/designs/$model 
wd=$outdir/designs/$model
# where model results are written
mkdir $outdir/$hemi.$model


# Create design matrix and contrast matrices
Rvar=$(which R)
$Rvar --slave --file=$scriptsdir/fsGLM_designMatrix.R --args "$lm" "$data" "$wd"


# Create image file to be analyzed (data are not smoothed at this point)
subjs=""
for sub in $(cat $wd/subjlist.txt); do
	subjs=$(echo $subjs --s $sub)
done

if [ ! -e "$homedir/$hemi.$meas.$template.n$n.mgh" ]; then
	qsub -V -b y -q all.q -S /bin/bash -o $logdir -e $logdir mris_preproc $subjs --hemi $hemi --meas $meas --target $template --out $homedir/$hemi.$meas.$template.n$n.mgh
fi


# Set contrasts
cons=""
for i in $(ls $wd/contrast*.mat); do
	cons=$(echo "$cons --C $i ")
done


# Store this file as a log file
cp $scriptsdir/fsGLM_tutorial.sh $wd
cp $data $wd


# Run the model
if [ -e "$homedir/$hemi.$meas.$template.n$n.mgh" ]; then
	mri_glmfit --glmdir $outdir/$hemi.$model --y $homedir/$hemi.$meas.$template.n$n.mgh  --X $wd/X.mat $cons --surf $template $hemi --fwhm $fwhm --save-yhat
	for img in $(ls $outdir/$hemi.$model/contrast*/sig.mgh); do
		output=$(dirname $img)
		mri_surfcluster --in $img --subject $template --fdr 0.05 --hemi $hemi --ocn $output/cluster.id.p05fdr.mgh --o $output/cluster.sig.p05fdr.mgh --sum $output/cluster.sum.p05fdr.txt
		mri_surfcluster --in $img --subject $template --fdr 0.01 --hemi $hemi --ocn $output/cluster.id.p01fdr.mgh --o $output/cluster.sig.p01fdr.mgh --sum $output/cluster.sum.p01fdr.txt
		mris_convert -c $output/cluster.id.p05fdr.mgh $SUBJECTS_DIR/$template/surf/$hemi.sphere $output/cluster.id.p05fdr.asc
		mris_convert -c $output/cluster.id.p01fdr.mgh $SUBJECTS_DIR/$template/surf/$hemi.sphere $output/cluster.id.p01fdr.asc
	done
	mris_convert -c $outdir/$hemi.$model/yhat.mgh $SUBJECTS_DIR/$template/surf/$hemi.sphere $outdir/$hemi.$model/yhat.asc
	mris_convert -c $outdir/$hemi.$model/rvar.mgh $SUBJECTS_DIR/$template/surf/$hemi.sphere $outdir/$hemi.$model/rvar.asc
	cp $homedir/$hemi.$meas.$template.n$n.mgh  $outdir/$hemi.$model
fi
