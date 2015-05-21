#!/bin/bash 

DIRECTED_TEST_MODE=0
RANDOM_TEST_MODE=0
DEBUG_WITH_ASSERTION=0
DESIGN_BUG_ANALYSIS=0
TEST_NAME=""
TEST_DIR=""
RESULT_DIR="../results"
RUN_OPTIONS=""
DUMP_FILE_NAME=""
DUMP_FILE_PATH=""
TEST_FILE_MICRO=""
UARCH_SIM="../cmodel/lc3b_uarch_simulator"
U_CODE="../cmodel/ucode6"
INSTANTIATE_ASSERTION="+define+INSTANTIATE_ASSERTION"
DESIGN_BUG_1=""

while [ "$1" ]
do
    case $1 in
        -*)  true ;
            case $1 in
                -d)     DIRECTED_TEST_MODE=1   # directed-tests
			TEST_NAME=$2	# directed-test name
                        shift 2;;
                -r)     RANDOM_TEST_MODE=1   # constrained-random tests
                        shift ;;
                -a)     DEBUG_WITH_ASSERTION=1 	# debug with assertions
                        shift ;;
		-x)	DESIGN_BUG_ANALYSIS=1	# design bug analysis
			shift ;;
                -*)
                        echo "Unrecognized argument $1"
                        shift ;;
            esac ;;  
    esac
done

if [ $DIRECTED_TEST_MODE == 1 ]; then
	TEST_DIR="../tests/directed_tests/${TEST_NAME}"
	DUMP_FILE_NAME=${TEST_NAME}
	if [ -d ${TEST_DIR} ]; then
		echo "${TEST_DIR} Directory Does Not Exists!"
	fi
elif [ $RANDOM_TEST_MODE == 1 ]; then
	TEST_DIR="../tests/random_tests"
	DUMP_FILE_NAME="rand_test"
else
	RANDOM_TEST_MODE=1
	TEST_DIR="../tests/random_tests"
	DUMP_FILE_NAME="rand_test"
fi

TEST_FILE_MICRO="+define+${DUMP_FILE_NAME}"
DUMP_FILE_PATH="${RESULT_DIR}/${DUMP_FILE_NAME}.rtl.dumpsim"
#DUMP_FILE_MICRO="+define+DUMP_FILE_PATH"

if [ $DEBUG_WITH_ASSERTION == 1 ]; then
	RUN_OPTIONS="${RUN_OPTIONS} -assertdebug -do run.do"
	if [ $DIRECTED_TEST_MODE == 1 ]; then
		echo "DIRECTED TEST WITH ASSERTIONS!"
	else
		echo "RANDOM TEST WITH ASSERTIONS!"
	fi
else
	RUN_OPTIONS="${RUN_OPTIONS} -c -do run.do"
	if [ $DIRECTED_TEST_MODE == 1 ]; then
		echo "DIRECTED TEST WITH NO ASSERTIONS!"
	else
		echo "RANDOM TEST WITH NO ASSERTIONS!"
	fi
fi

if [ $DESIGN_BUG_ANALYSIS == 1 ]; then
	if [ $TEST_NAME == "test2" ]; then
		echo "Successfully Activate the Design Bug 1!"
		DESIGN_BUG_1="+define+DESIGN_BUG_ANALYSIS_1"
	else
		echo "Wrong Test Case Activated!"
	fi
fi


echo	"==================================================="
echo	"|		GOLDEN MODEL SIMULATION		  |"
echo	"==================================================="

source ${TEST_DIR}/runtest.sh

if [ -f dumpsim ]; then
	rm dumpsim
fi

echo	"==================================================="
echo	"|		RTL MODEL SIMULATION		  |"
echo	"==================================================="

if [ ! -d work ]; then
	vlib work
fi

if [ $DEBUG_WITH_ASSERTION == 0 ]; then

	vlog +libext+.v \
	+incdir+../rtl/+../tb \
	-y ../rtl -y ../tb \
	+cover=bcesfx ../tb/tb.v \
	+define+DUMP_FILE_PATH=\"$DUMP_FILE_PATH\" \
	${TEST_FILE_MICRO} \
	${DESIGN_BUG_1}

	vsim tb ${RUN_OPTIONS}
	#vsim -voptargs="+acc=rnpc" -voptargs="+acc=a" -coverage tb ${RUN_OPTIONS}

echo	"==================================================="
echo	"|		RTL vs. C MODEL CHECKING	  |"
echo	"==================================================="

	if [ -f ${RESULT_DIR}/${DUMP_FILE_NAME}.cmodel.dumpsim ] && [ -f ${RESULT_DIR}/${DUMP_FILE_NAME}.rtl.dumpsim ]; then
		echo	"Checking Result..."
		vim ${RESULT_DIR}/${DUMP_FILE_NAME}.rtl.dumpsim
		vim ${RESULT_DIR}/${DUMP_FILE_NAME}.cmodel.dumpsim
		vim -d ${RESULT_DIR}/${DUMP_FILE_NAME}.rtl.dumpsim ${RESULT_DIR}/${DUMP_FILE_NAME}.cmodel.dumpsim
	else
		echo	"Dump File Not Complete!"
	fi
else

echo	"==================================================="
echo	"|		DEBUG WITH ASSERTION		  |"
echo	"==================================================="

	vlog +libext+.v \
	+incdir+../rtl/+../tb \
	-y ../rtl -y ../tb \
	+cover=bcesfx ../tb/tb.v \
	+define+DUMP_FILE_PATH=\"$DUMP_FILE_PATH\" \
	${TEST_FILE_MICRO} \
	${INSTANTIATE_ASSERTION} \
	${DESIGN_BUG_1}

	vlog -sv ../tb/test.sv
	vsim -voptargs="+acc=rnpc" -voptargs="+acc=a" -coverage tb ${RUN_OPTIONS}
	
fi
