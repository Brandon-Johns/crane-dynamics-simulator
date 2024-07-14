/*
Written By: Brandon Johns
Date Version Created: 2022-02-21
Date Last Edited: 2022-02-21
Purpose: Run exported c/c++ equations
Status: functional
Simulator: CDS

%%% PURPOSE %%%

%%% VERSION CHANGES %%%
Update for CDS
Update for SUNDIALS v6.1.1

%%% TODO %%%

%%% NOTES %%%
Requires minimum SUNDIALS v6

*/

#include <stdio.h>
#include <iostream>

#define _USE_MATH_DEFINES /* Tells math.h to define: M_PI, DEG2RAD, ... */
#include <math.h>

#include <cvode/cvode.h>               // prototypes for CVODE fcts., consts.
#include <nvector/nvector_serial.h>    // access to serial N_Vector
#include <sunmatrix/sunmatrix_dense.h> // access to dense SUNMatrix
#include <sunlinsol/sunlinsol_dense.h> // access to dense SUNLinearSolver
#include <sundials/sundials_types.h>   // defs. of sunrealtype, sunindextype

#include <armadillo>

//####################################################################################
// Macros & Global Vars
//##########################################
// Vector and matrix component access (Sundials)
//		ith   component of vector v, indexed i=[1,numX]
//		i,jth component of matrix A, indexed i=[1,numX],j=[1,numX]
#define Ith(v,i)    NV_Ith_S(v,(i-1))
#define IJth(A,i,j) SM_ELEMENT_D(A,(i-1),(j-1))

// Mathematical Constants
constexpr sunrealtype ZERO = 0.0;
constexpr sunrealtype pi = M_PI;				// Used by matlab exported equations
constexpr sunrealtype RAD2DEG = M_PI/180.0;
constexpr sunrealtype DEG2RAD = 180.0*M_1_PI;	// M_1_PI = 1/pi

// Solver control
constexpr sunrealtype relTol = 1.0e-7;	// scalar relative tolerance
constexpr sunrealtype absTol = 1.0e-7;	// vector absolute tolerance components - give them all the same ;P

// Output solution at times
constexpr sunrealtype t_initial = 0.0;
constexpr sunrealtype dt = 0.02;

//##########################################
// Include auto-generated code
//##########################################
// Same across all version of a crane:
//	t_final
//	Constants
#include <crane_head_shared.cpp>

// Per crane:
//	Vector dimensions (numQF, numX, numConstraints)
//	Head of csv
//	Initial conditions
#include <crane_head.cpp>

//####################################################################################
// Prototypes
//##########################################
// Functions Called by the Solver
static int ODEs(sunrealtype t, N_Vector sys_x, N_Vector sys_xd, void *user_data);

// Output solution
static void Print_ConfigSpace_Head();
static void Print_ConfigSpace(sunrealtype t, N_Vector x);

// Sundials interfacing helper functions
static void Print_SunStats(void *cvode_mem);
static int Check_SunReturnValue(void *returnValue, const char *funcName, int opt);

//####################################################################################
// Main
//##########################################
int main()
{
	int retval;
	int retval_cvode;
	sunindextype idx;
	sunrealtype t_now;
	sunrealtype t_next;
	SUNContext sunContext;
	N_Vector x = NULL;
	N_Vector abstol = NULL;
	SUNMatrix A = NULL;
	SUNLinearSolver LS = NULL;
	
	void *cvode_mem;
	cvode_mem = NULL;

	// Create the SUNDIALS context
	retval = SUNContext_Create(NULL, &sunContext);
	if(Check_SunReturnValue(&retval, "SUNContext_Create", 1)) return(1);

	// Create vectors for state & abstol
	x      = N_VNew_Serial(numX, sunContext);
	abstol = N_VNew_Serial(numX, sunContext);
	if(Check_SunReturnValue((void *)x,      "N_VNew_Serial", 0)) return(1);
	if(Check_SunReturnValue((void *)abstol, "N_VNew_Serial", 0)) return(1);

	// Initialise
	//	Initial conditions
	//	Vector absolute tolerance
	for(idx = 1; idx <= numX; idx++)
	{
		Ith(x, idx) = x_ICs[idx-1];
		Ith(abstol, idx) = absTol;
	}

	// Create the solver memory
	// Specify solver to use Backward Differentiation Formula
	cvode_mem = CVodeCreate(CV_BDF, sunContext);
	if(Check_SunReturnValue((void *)cvode_mem, "CVodeCreate", 0)) return(1);

	// Initialise the integrator memory
	// Specify
	//	Function that computes x'=f(t,x)
	//	Inital time
	//	Initialised state vector x
	retval = CVodeInit(cvode_mem, ODEs, t_initial, x);
	if(Check_SunReturnValue(&retval, "CVodeInit", 1)) return(1);

	// Specify
	//	Scalar relative tolerance
	//	Vector absolute tolerances
	retval = CVodeSVtolerances(cvode_mem, relTol, abstol);
	if(Check_SunReturnValue(&retval, "CVodeSVtolerances", 1)) return(1);

	// Create dense SUNMatrix for use in linear solves
	A = SUNDenseMatrix(numX, numX, sunContext);
	if(Check_SunReturnValue((void *)A, "SUNDenseMatrix", 0)) return(1);

	// Create dense SUNLinearSolver object for use by CVode
	LS = SUNLinSol_Dense(x, A, sunContext);
	if(Check_SunReturnValue((void *)LS, "SUNLinSol_Dense", 0)) return(1);

	// Attach the matrix and linear solver to CVode
	retval = CVodeSetLinearSolver(cvode_mem, LS, A);
	if(Check_SunReturnValue(&retval, "CVodeSetLinearSolver", 1)) return(1);

	//##########################################
	// Options to experiment with more
	//##########################################
	// Maximum internal steps between each solver return
	//   -1=Disable, 500=Default
	long int MaxNumInternalSteps = 10000; // Only roughly chosen. Any bigger takes much too long before failing
	retval = CVodeSetMaxNumSteps(cvode_mem, MaxNumInternalSteps);
	if(Check_SunReturnValue(&retval, "CVodeSetMaxNumSteps", 1)) return(1);

	//##########################################
	// Solve
	//##########################################
	// Print csv head
	Print_ConfigSpace_Head();

	// Solve ODE & print solution
	for(t_next=dt; t_next<=t_final; t_next+=dt)
	{
		// Solve up to next output time 't_next'
		//	Solver doesn't necessarily find this time exactly
		//	=> t_now is the exact solution time
		retval_cvode = CVode(cvode_mem, t_next, x, &t_now, CV_NORMAL);

		// Print csv row
		Print_ConfigSpace(t_now, x);

		// Check for solver fails
		if(Check_SunReturnValue(&retval_cvode, "CVode", 1)) break;
	}

	// Print solver statistics
	Print_SunStats(cvode_mem);

	// Free memory
	N_VDestroy(x);
	N_VDestroy(abstol);
	CVodeFree(&cvode_mem);
	SUNLinSolFree(LS);
	SUNMatDestroy(A);
	SUNContext_Free(&sunContext);

	// Return last solver retval
	printf("\n");
	printf("CDS_INFO: Final CVODE retval = %d\n\n", retval_cvode);
	return(retval_cvode);
}


//####################################################################################
// Functions called by the solver
//##########################################
// Compute ODEs: xd = f(t,x)
static int ODEs(sunrealtype t, N_Vector sys_x, N_Vector sys_xd, void *user_data)
{
	sunindextype idx_x;
	double sys_M_order2[numQF][numQF];
	double sys_f_b[numQF][1];
	double sys_f_c[numQF][1];
	double sys_f_dT[1][numQF];
	double sys_f_e[1][1];

	//##########################################
	// Include auto-generated code
	//##########################################
	// x (state vector)
	#include <crane_x.cpp>

	// u (system inputs)
	#include <crane_inputs.cpp>

	// Common subexpressions & ODE segments
	#include <crane_ode.cpp>

	//##########################################
	// Generalised
	//##########################################
	// Create new x matrix for arma (no sharing between sun & arma)
	//arma::mat::fixed<numX, 1> sys_x_arma = NV_DATA_S(sys_x);

	// Give pointers to arma
	//	See Doc: "Matrix, Vector, Cube and Field Classes" > "mat" > "Advanced constructors"
	arma::mat M_order2(*sys_M_order2, numQF, numQF, false, true);
	M_order2 = M_order2.t(); // Convert (matlab ccode() result -> arma): row major -> column major order
	arma::mat f_b(*sys_f_b, numQF, 1, false, true);
	arma::mat f_c(*sys_f_c, numQF, 1, false, true);
	arma::mat f_dT(*sys_f_dT, 1, numQF, false, true);
	arma::mat f_e(*sys_f_e, 1, 1, false, true);

	// Solve
	arma::mat::fixed<numQF, 1> f_mb;
	arma::mat::fixed<numQF, 1> f_mc;
	double f_lambda;
	arma::mat::fixed<numQF, 1> q_free_dd;
	if(numConstraints != 0)
	{
		f_mb = arma::solve(M_order2, f_b);
		f_mc = arma::solve(M_order2, f_c);
		f_lambda = arma::as_scalar( (f_e - f_dT*f_mc)/(f_dT*f_mb) );
		q_free_dd = -f_mc - f_lambda*f_mb;
	}
	else // numConstraints == 0
	{
		q_free_dd = - arma::solve(M_order2, f_c);
	}

	// Pass data to Sundials
	//	sys_xd = [q_free_dd; sys_x(1:numQF]
	for(idx_x=1; idx_x<=numQF; idx_x++)
	{
		Ith(sys_xd, idx_x)       = q_free_dd(idx_x-1);
		Ith(sys_xd, idx_x+numQF) = Ith(sys_x, idx_x);
	}

	return(0);
}

// Print head of csv holding the solution
static void Print_ConfigSpace_Head()
{
	printf(x_sym);
	printf("\n");
	return;
}

// Print current row of csv holding the solution
//	Assuming double precision for printing
static void Print_ConfigSpace(sunrealtype t, N_Vector x)
{
	sunindextype idx;

	// Print: Time
	printf("%.6e", t);

	// Print: x
	// NV indexing starts at 0
	for(idx = 1; idx <= numX; idx++)
	{
		printf(",%.6e", Ith(x, idx));
	}

	printf("\n");
	return;
}

//####################################################################################
// Sundials interfacing helper functions
//##########################################
// Get and print solver statistics
static void Print_SunStats(void *cvode_mem)
{
	long int tmp;
	int retval;
	printf("\n");
	printf("CDS_INFO: Solver Statistics\n");

	retval = CVodeGetNumSteps(cvode_mem, &tmp);
	Check_SunReturnValue(&retval, "Stats 1", 1); printf("\tSteps     = %ld\n", tmp);
	retval = CVodeGetNumRhsEvals(cvode_mem, &tmp);
	Check_SunReturnValue(&retval, "Stats 2", 1); printf("\tODE Evals = %ld\n", tmp);
	retval = CVodeGetNumJacEvals(cvode_mem, &tmp);
	Check_SunReturnValue(&retval, "Stats 3", 1); printf("\tJacobian Evals = %ld\n", tmp);
	retval = CVodeGetNumLinRhsEvals(cvode_mem, &tmp);
	Check_SunReturnValue(&retval, "Stats 4", 1); printf("\tLinear Evals   = %ld\n", tmp);
	retval = CVodeGetNumLinSolvSetups(cvode_mem, &tmp);
	Check_SunReturnValue(&retval, "Stats 5", 1); printf("\tLinear Solve Setups        = %ld\n", tmp);
	retval = CVodeGetNumErrTestFails(cvode_mem, &tmp);
	Check_SunReturnValue(&retval, "Stats 6", 1); printf("\tLocal error Test Fails     = %ld\n", tmp);
	retval = CVodeGetNumNonlinSolvIters(cvode_mem, &tmp);
	Check_SunReturnValue(&retval, "Stats 7", 1); printf("\tNonlinear Solve Iters      = %ld\n", tmp);
	retval = CVodeGetNumNonlinSolvConvFails(cvode_mem, &tmp);
	Check_SunReturnValue(&retval, "Stats 8", 1); printf("\tNonlinear Solve Conv Fails = %ld\n", tmp);
	retval = CVodeGetNumGEvals(cvode_mem, &tmp);
	Check_SunReturnValue(&retval, "Stats 9", 1); printf("\tUser Root Function Evals   = %ld\n", tmp);

	return;
}


// Check Sundials function return value
//	opt == 0 means SUNDIALS function allocates memory so check if
//		returned NULL pointer
//	opt == 1 means SUNDIALS function returns an integer value so check if
//		retval < 0
//	opt == 2 means function allocates memory so check if returned
//		NULL pointer
static int Check_SunReturnValue(void *returnValue, const char *funcName, int opt)
{
	int *retval;

	// Error if SUNDIALS function returned NULL pointer - no memory allocated
	if(opt == 0 && returnValue == NULL) {
		fprintf(stderr, "\nCDS_ERROR: %s() failed - returned NULL pointer\n\n", funcName);
		return(1);
	}

	// Error if retval < 0
	else if(opt == 1) {
		retval = (int *) returnValue;
		if(*retval < 0) {
			fprintf(stderr, "\nCDS_ERROR: %s() failed with retval = %d\n\n", funcName, *retval);
			return(1);
		}
	}

	// Error if function returned NULL pointer - no memory allocated
	else if(opt == 2 && returnValue == NULL) {
		fprintf(stderr, "\nCDS_ERROR: %s() failed - returned NULL pointer\n\n", funcName);
		return(1);
	}

	return(0);
}


