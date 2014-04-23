#===============================================================================
# Prepare the prerequisites for running experiments
#===============================================================================

# Paths
SUN397 := /SUN397
SUN397R500 := /SUN397-R500
SUN397R100K := /SUN397-R100K

# Matlab compiler
MATLAB := matlab
MATLAB_FLAGS := -nodisplay -nojvm -nosplash
MCC := mcc
#MCC_FLAGS := -R -singleCompThread -R -nodisplay -R -nosplash -v
MCC_FLAGS := -R -nodisplay -R -nosplash -v

#===============================================================================

.PHONY: movecache zipdiary clean cleanbin cleanmcc cleantxt \
	ex exmtl r500 r100k


#-------------------------------------------------------------------------------
# Usage
#-------------------------------------------------------------------------------
all:
	@echo "usage: make <command>"
	@echo
	@echo "Experiments:"
	@echo "   ex         Make experiments"
	@echo "   exmtl      Make MTL experiments"
	@echo
	@echo "Datasets (resized versions of the SUN397 dataset):"
	@echo "   r500       Create the SUN397-R500 \
(the largest dimension is at most 500 pixels)"
	@echo "   r100k      Create the SUN397-R100K \
(total image area is at most 100K pixels)"
	@echo
	@echo "Cleanup:"
	@echo "   movecache  Move cache folders around."
	@echo "   zipdiary   Archive diary files."
	@echo "   clean      Clean everything defined below."
	@echo "   cleanbin   Clean binary (mcc compiled) files."
	@echo "   cleanmcc   Clean mcc auxiliary files."
	@echo "   cleantxt   Clean txt files."


#-------------------------------------------------------------------------------
# Experiments
#-------------------------------------------------------------------------------

ex: seval cleanmcc
	@echo "Creating command files for running experiments..."
	make/make_cmd_experiments.sh "experiments-scripts" "seval" \
		"1"  "5 10 20 50" "hell"
		#"1"  "5 10 20 50" "linear hell"
		#"1"  "5 10 20 50" "chi2"
		#"2 3 4 5 6 7 8 9 10"  "5 10 20 50" "hell"
		#"2 3 4 5 6 7 8 9 10"  "5 10 20 50" "linear hell"

exmtl: seval cleanmcc
	@echo "Creating command files for running experiments..."
	make/make_cmd_mtlexperiments.sh "experiments-scripts-mtl" "seval" \
		"1 2 3 4 5 6 7 8 9 10" "50" "hell" "M" "1e-3" "1e+5"
		#"1" "5 10 20 50" "hell" "S" "1e-4 1e-3 1e-2 1e-1 1 1e+1 1e+2 1e+3 1e+4" "0"
		#"1"  "5 10 20 50" "hell" "M" "1e-5 1e-4 1e-3 1e-2 1e-1" "1 1e+1 1e+2 1e+3 1e+4 1e+5"
		#"1 2 3 4 5 6 7 8 9 10" "5 10 20 50" "hell" "S" "1" "0"
		#"1 2 3 4 5 6 7 8 9 10" "5 10 20 50" "hell" "M" "1e-3" "1e+4"
		#"1 2 3 4 5 6 7 8 9 10" "5 10" "hell" "M" "1e-2" "1e+3"
		#"1 2 3 4 5 6 7 8 9 10" "20" "hell" "M" "1e-3" "1e+3"
		#"1 2 3 4 5 6 7 8 9 10" "50" "hell" "M" "1e-3" "1e+5"

seval: lib/utility/seval.m
	@echo "Compiling '$<'..."
	$(MATLAB) $(MATLAB_FLAGS) -r \
		"cd $(CURDIR); $(MCC) $(MCC_FLAGS) -m $< \
		-N -p images -p shared -a recognition \
		-a lib/utility -a lib/mtlsdca \
		-a lib/vlfeat/toolbox/mex/mexa64 -a lib/vlfeat -a lib/yael \
		; quit"


#-------------------------------------------------------------------------------
# Datasets
#-------------------------------------------------------------------------------

r500:
	make/make_resize.sh "$(SUN397)" "jpg" "$(SUN397R500)" "png" "500x500>"
	cp splits/png/split10_*.mat "$(SUN397R500)"

r100k:
	make/make_resize.sh "$(SUN397)" "jpg" "$(SUN397R100K)" "png" "100000@"
	cp splits/png/split10_*.mat "$(SUN397R100K)"


#-------------------------------------------------------------------------------
# Cleanup
#-------------------------------------------------------------------------------

movecache:
	make/make_movecache.sh "experiments" "/scratch"

zipdiary:
	make/make_zipdiary.sh "experiments"

clean: cleanbin cleanmcc cleantxt

cleanbin:
	rm -f seval

cleanmcc:
	rm -f readme.txt mcc*.log run_*.sh

cleantxt:
	rm -rf *.txt
