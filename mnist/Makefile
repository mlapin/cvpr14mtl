# Matlab compiler
MATLAB := matlab
MATLAB_FLAGS := -nodisplay -nojvm -nosplash
MCC := mcc
#MCC_FLAGS := -R -singleCompThread -R -nodisplay -R -nosplash -v
MCC_FLAGS := -R -nodisplay -R -nosplash -v

#===============================================================================

.PHONY: clean cleanbin cleanmcc cleantxt

#-------------------------------------------------------------------------------
# Experiments
#-------------------------------------------------------------------------------

all: experiments logs results
	@echo "Creating command files for running experiments..."
	./make_cmd_experiments.sh "experiments" \
		"5 10 20 50 100"  "1e-3" "1e-3"

logs:
	mkdir -p logs

results:
	mkdir -p results

experiments: experiments.m
	@echo "Compiling '$<'..."
	$(MATLAB) $(MATLAB_FLAGS) -r \
		"cd $(CURDIR); \
		$(MCC) $(MCC_FLAGS) -m $< -N -p shared -a mex; \
		quit;"


#-------------------------------------------------------------------------------
# Cleanup
#-------------------------------------------------------------------------------

clean:
	rm -f experiments *.txt mcc*.log run_*.sh
