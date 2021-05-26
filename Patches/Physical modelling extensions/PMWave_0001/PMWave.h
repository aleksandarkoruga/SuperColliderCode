#pragma once
#include <algorithm>
#include <stdlib.h>
#include <math.h>
#include <time.h>  
#include <cmath>
#include <iostream>
#include <vector>
#include <numeric>
#include "SC_PlugIn.h"



//using namespace std;
// Global pointer used by SC, has to be named ft
static InterfaceTable *ft;

// Use a struct to define the UGen class, inherits from Unit
struct PMWave : public Unit
{
	
        // plate variables,  initialize _meanLength; recalculate  _meanLength ;   glissandi!!ok dly=100  ok
                        int n=2;
						float _time=0.5;//in5 is TIME to n
						float _damping=0.99999;
						float _cutoff=0.2;
						std::vector<std::vector<float> > _meanLength;
						uint _nJunctionsX = 3 ;
						uint _nJunctionsY = 3;
						//envd is the speed from one output channel to another , damp=damping
						float envd=0.03; 
						
                        float _speed=0.8f;
						
						
						std::vector<std::vector<float> > sens;
						std::vector<std::vector<float> > rsens;
						std::vector<std::vector<float> > _rand1;
						std::vector<std::vector<float> > _rand2;
						//float _rand1[3][3]={};
						//float _rand2[3][3]={};
						//float dsens[3][3]={};
						//float rsens[3][3]={};
						
						
						//float dly[3][3]={};
						

						//init in constructor
						std::vector<std::vector<float> > _currentDistance;
						

						//init in constructor
						std::vector<std::vector<std::vector<float> > > _p0;
						std::vector<std::vector<std::vector<float> > > _p1;
						std::vector<std::vector<std::vector<float> > > _p2;
						std::vector<std::vector<std::vector<float> > > _p3;
						
						/*float  p0[3][3][2000]={};
						float  p1[3][3][2000]={};
						float  p2[3][3][2000]={};
						float  p3[3][3][2000]={};
						 */
						
					/*	float p[3][3]={};	
						int ddup[3][3]={};
						int dwn[3][3]={};
						float d[3][3]={};    */

						//float  del[4]={};

						float  ddiv=0.5;
						int w=0;
						
						
                        
						float envch=0;
						
                        
                        
                        
						 	
                       
						
				      
                        int   in_x=0; // where to write x 
                        int   in_y=0; //  where to write y 
                        
						int _x=2; //where to read x
                        int _y=2; //where to read y
						int _xOld=0;
						int _yOld=1;

                       	float _randAmt1=0.;
					  	float _randAmt2=0.;
					   	
						//define inside methods here


void _setDamping(const float _damp);

void _updateTimeMeanLength(const float _inTime);
void _updateSpeed(const float _inSpeed);
float _render(const float _in);
void _updateRandAmt1(const float _randAmt);
void _updateRandAmt2(const float _randAmt);
void _resetRandom();
void _setCutoff(const float _cut);
float getInvSampleRate(){return (float) (1/mRate->mSampleRate);}

float _fclipf(const float _in,const float _min,const float _max)
{
	return fminf(fmaxf(_in,_min),_max);
};





};


// Functions external to the UGen:
extern "C"
{
	// Definition for the audio calculation function
	void PMWave_next(PMWave *unit, int numSamples);

	// Definition of the constructor
	void PMWave_Ctor(PMWave *unit);
};

