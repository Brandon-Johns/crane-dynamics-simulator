Date:		2021-11-29
Version:	craneExp1_3

************************************************************
Actuation
******************************
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
// Z rotation:            -0.209132
// Z axis alignment error:0.960889
// r = 1121.73 (0.968463)
// x = -919.607 (0.269086)
// y = -525.927 (0.544553)
// z = 954.624 (0.476496)
arma::Mat<double> BoomHead_0up = arma::Mat<double>({ {0.999924,0.0097123,0.00757355,200.802}, {-0.00979694,0.999889,0.0112204,-566.997}, {-0.00746373,-0.0112938,0.999908,1022.36}, {0,0,0,1} });
arma::Mat<double> BoomHead_45up = arma::Mat<double>({ {0.706048,0.0131777,-0.708042,-175.56}, {0.00127932,0.999801,0.0198836,-567.222}, {0.708163,-0.0149446,0.705891,1794.71}, {0,0,0,1} });
double L_UR5Base_BH = 1121.73;
arma::Col<double> P_ViconGlobal_UR5Base = arma::Col<double>({ -919.607,-525.927,954.624 });
double Rz_ViconGlobal_UR5Base = -0.00365004;

************************************************************
Data Files
******************************
Error from calibrated pose: Angle [deg] = 0.722596
Error from calibrated pose: norm(P) [mm] = 1.36688
Hook Block height: z [mm] = 1142.17

./ExpMain1_3 1 raw_motion1_PH_3p
./ExpMain1_3 2 raw_motion2_PH_3p
./ExpMain1_3 3 raw_motion3_PH_3p
./ExpMain1_3 1 raw_motion1_PH_2p
./ExpMain1_3 2 raw_motion2_PH_2p
./ExpMain1_3 3 raw_motion3_PH_2p

./ExpMain1_3 1 raw_motion1_PL_2p
./ExpMain1_3 2 raw_motion2_PL_2p
./ExpMain1_3 3 raw_motion3_PL_2p
./ExpMain1_3 1 raw_motion1_PL_3p
./ExpMain1_3 2 raw_motion2_PL_3p
./ExpMain1_3 3 raw_motion3_PL_3p


Error from calibrated pose: Angle [deg] = 0.765108
Error from calibrated pose: norm(P) [mm] = 1.13787
Hook Block height: z [mm] = 1140.78


./ExpMain1_3 1 raw_motion1_PL_FC
./ExpMain1_3 2 raw_motion2_PL_FC
./ExpMain1_3 3 raw_motion3_PL_FC

