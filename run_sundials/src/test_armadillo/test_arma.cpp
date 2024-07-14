/*
Written by:			Brandon Johns
Version created:	2021-10-07
Last edited:		2021-10-07

Purpose:
	Test armadillo install

*/

#include <iostream>
#include <armadillo>

int main()
{
	arma::mat A(4, 5, arma::fill::randu);
	arma::mat B(4, 5, arma::fill::randu);
	
	std::cout << A*B.t() << std::endl;

	return 0;
}
