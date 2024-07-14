Date:		2021-12-16
Version:	craneExp1_3

************************************************************
Actuation
******************************
if(motionMode == MotionMode(Stationary))
{
	// Do nothing
}
else if(motionMode == MotionMode(Test))
{
	double amplitudeB = 60; // deg
	q[BJ::base] = q_start[BJ::base] + (t_now/t_max) * (amplitudeB * M_PI/180);
}
else if(motionMode == MotionMode(motion1))
{
	double amplitudeB = 35; // deg
	double periodB = 5; // seconds
	double amplitudeS = 22.5; // deg !!DO NOT INCREASE PAST 22.5!!
	double periodS = double(15)/double(4); // seconds
	q[BJ::base] = q_start[BJ::base] + (t_now/t_max) * (amplitudeB * M_PI/180) * sin((2*M_PI/periodB)*t_now);
	q[BJ::shdr] = q_start[BJ::shdr] + (t_now/t_max) * (amplitudeS * M_PI/180) * ( cos((2*M_PI/periodS)*t_now) - 1 );
}
else if(motionMode == MotionMode(motion2))
{
	double amplitudeS = 22.5; // deg !!DO NOT INCREASE PAST 22.5!!
	double periodS = double(15)/double(4); // seconds
	q[BJ::shdr] = q_start[BJ::shdr] + ((t_now)/t_max) * (amplitudeS * M_PI/180) * ( cos((2*M_PI/periodS)*t_now) - 1 );
}
else if(motionMode == MotionMode(motion3))
{
	double amplitudeB = 35; // deg
	double periodB = 2.5; // seconds
	q[BJ::base] = q_start[BJ::base] + ((t_now)/t_max) * (amplitudeB * M_PI/180) * sin((2*M_PI/periodB)*t_now);
}

************************************************************
Calibration
******************************
// Calibration Results (mm & deg), value(stddev): 
// Z rotation:            -25.7567
// Z axis alignment error:0.407964
// r = 1125.91 (0.453753)
// x = -1177.99 (0.253783)
// y = 145.878 (0.507019)
// z = 958.273 (0.521642)
arma::Mat<double> BoomHead_0up = arma::Mat<double>({ {0.999822,0.0182177,0.00498719,-53.6166}, {-0.0182406,0.999823,0.00457644,103.892}, {-0.00490294,-0.0046666,0.999977,1024.22}, {0,0,0,1} });
arma::Mat<double> BoomHead_45up = arma::Mat<double>({ {0.703046,0.0140963,-0.711004,-429.401}, {-0.00569429,0.999883,0.0141931,103.134}, {0.711121,-0.00592973,0.703044,1800.49}, {0,0,0,1} });
double L_UR5Base_BH = 1125.91;
arma::Col<double> P_ViconGlobal_UR5Base = arma::Col<double>({ -1177.99,145.878,958.273 });
double Rz_ViconGlobal_UR5Base = -0.449539;


************************************************************
Data Files
******************************
./ExpMain1_4 s PL withT
./ExpMain1_4 s PL withoutT

BJ: Error from calibrated pose: Angle [deg] = 0.745137
BJ: Error from calibrated pose: norm(P) [mm] = 1.37228
BJ: Hook Block height: z [mm] = 1146.65

BJ: Error from calibrated pose: Angle [deg] = 44.7304
BJ: Error from calibrated pose: norm(P) [mm] = 1852.62
BJ: Hook Block height: z [mm] = 1146.65


