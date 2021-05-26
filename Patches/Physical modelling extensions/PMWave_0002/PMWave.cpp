#include "SC_PlugIn.h"
#include <algorithm>
#include <stdlib.h>
#include <math.h>
#include <time.h>  
#include <cmath>
//#include <iostream>

#include <numeric>

//#include <vector>


// Global pointer used by SC, has to be named ft
static InterfaceTable *ft;


	 



// Use a struct to define the UGen class, inherits from Unit
struct PMWave : public Unit
{
						
						int _nJunctionsX;
						int _nJunctionsY;
						int n;
						
	//initialize global vectors
	float _currentDistance[3][3];
	float _meanLength[3][3];
	float sens[3][3];
	float rsens[3][3];


	float _p0[3][3][1000];
	float _p1[3][3][1000];
	float _p2[3][3][1000];
	float _p3[3][3][1000];


	float _del[4];

	int _dwn[3][3];
	int _ddup[3][3];
	float _fractional[3][3];
	float _rand1[3][3];
	float _rand2[3][3];
	float _p[3][3];
	
                        
						float _time;//=50;// TIME to n
						float _damping;//=0.99999;
						float _cutoff;//=0.2;					
                        float _speed;//=0.8f;
						
					
						float  ddiv;//=0.5;
						int w;//=0;						                       
						float envch;//=0;
                        int   in_x;//=0; // where to write x 
                        int   in_y;//=0; //  where to write y 
                        float envd;//=0.03; 
						int _x;//=2; //where to read x
                        int _y;//=2; //where to read y
						int _xOld;//=0;
						int _yOld;//=1;

                       	float _randAmt1;//=0.;
					  	float _randAmt2;//=0.;
		


//void _setDamping(const float _damp);

//void _updateTimeMeanLength(const float _inTime);
//void _updateSpeed(const float _inSpeed);
//float _render(const float _in);
//void _updateRandAmt1(const float _randAmt);
//void _updateRandAmt2(const float _randAmt);
//void _resetRandom();
//void _setCutoff(const float _cut);
float getInvSampleRate(){return (float) (1/mRate->mSampleRate);}



 void _updateTimeMeanLength(const float _inTime)
 {
	

	_time=n * _fclipf(_inTime,0,1);

	 for(int i=0;i<_nJunctionsX;i++)	
	{
		for(int j=0;j<_nJunctionsY;j++)
		{	
			_meanLength[i][j] = _fclipf((_time+(2*_rand1[i][j]*_randAmt1)),1,n );
		}
					
	}
	 
 }

void _updateSpeed(const float _inSpeed)
{
	_speed=_fclipf(_inSpeed,0,1);
    for(int i=0;i<_nJunctionsX;i++)
    {
        for(int j=0;j<_nJunctionsY;j++)
        {
			sens[i][j]= _fclipf(_speed+(2.0f*_rand2[i][j]*_randAmt2) ,getInvSampleRate() ,1.0f) ; 
			rsens[i][j]=sens[i][j];  
		
		}
        			
    }  

}



void _updateRandAmt1(const float _randAmt)
{
			_randAmt1=_randAmt;
        		
        	for(int i=0;i<_nJunctionsX;i++)	
			{
				for(int j=0;j<_nJunctionsY;j++)
				{
						_meanLength[i][j] = _fclipf(_time+(2*_rand1[i][j]*_randAmt1),1,(float)n );
				}
			}
        		
        		
}

void _updateRandAmt2(const float _randAmt)
{
			_randAmt2=_randAmt;
        		for(int i=0;i<_nJunctionsX;i++)
        		{
        			for(int j=0;j<_nJunctionsY;j++)
        		{
					sens[i][j]=     _fclipf(_speed+(2*_rand2[i][j]*_randAmt2),getInvSampleRate(),1.0f ) ; 
					rsens[i][j]=sens[i][j];
				}
        			
        		}  
        		
        		
}
void _setDamping(const float _damp){_damping=_damp;}
void _setCutoff(const float _cut){_cutoff=_cut;}

void _resetRandom(){
        	//((rand() / (float)RAND_MAX)-0.5f)
        		for(int i=0;i<_nJunctionsX;i++)
        		{
        			for(int j=0;j<_nJunctionsY;j++)
					{
						_rand1[i][j]=  ((rand() / (float)RAND_MAX)-0.5f)  ; 
						_rand2[i][j]=  ((rand() / (float)RAND_MAX)-0.5f)  ; 
						sens[i][j]=     _fclipf(_speed+(2.0f*_rand2[i][j]*_randAmt2) ,getInvSampleRate(),1.0f) ; 
						rsens[i][j]=sens[i][j];
						_meanLength[i][j] = _fclipf(_time+(2*_rand1[i][j]*_randAmt1),1,(float)n) ;
				 
					 }
        			
        		}  
        		
        	}



float _fclipf(const float _in,const float _min,const float _max)
{
	return fminf(fmaxf(_in,_min),_max);
}


 float _render(const float _in){     
       
  
				//MAIN LOOP on plate
				
				for(int ii=0;ii<_nJunctionsX;ii++)
				{
					for(int jj=0;jj<_nJunctionsY;jj++)   
					{
					
                        
                       
                        //s=0 n=1 e= 2 w=3
                        
                        
                        
                        //GLISSANDOS BETWEEN JUNCTIONS
						
						//distance between value to reach and current value
						float dsens=std::abs(_meanLength[ii][jj]  -_currentDistance[ii][jj]);

				        sens[ii][jj]= dsens<sens[ii][jj]? dsens: rsens[ii][jj];  
                        _currentDistance[ii][jj]+=_currentDistance[ii][jj]<_meanLength[ii][jj] ? (sens[ii][jj]):  ( _currentDistance[ii][jj]>_meanLength[ii][jj] ? (-sens[ii][jj]):0);
						
						
                        
                        //get int + fract distance from target pointer to current position & +1 (for interpolation)
						 						
						_dwn[ii][jj]=(int)_currentDistance[ii][jj];
						_ddup[ii][jj]=_dwn[ii][jj]+1;
						_fractional[ii][jj]=fmodf(_currentDistance[ii][jj],1.0f);

// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
						//junction update
	
						_del[0]=((  _p0[ii][((jj-1)+_nJunctionsY)%_nJunctionsY][(w+_dwn[ii][jj])%n]  )*(1.0-_fractional[ii][jj]) +(_p0[ii][((jj-1)+_nJunctionsY)%_nJunctionsY][(w+_ddup[ii][jj])%n] )*_fractional[ii][jj]);	                       												
						_del[1]=((_p1[ii][(jj+1)%_nJunctionsY][(w+_dwn[(ii+1)%_nJunctionsX][jj])%n]  )*(1-_fractional[(ii+1)%_nJunctionsX][jj])+   (_p1[ii][(jj+1)%_nJunctionsY][(w+_ddup[(ii+1)%_nJunctionsX][jj])%n]  )*_fractional[(ii+1)%_nJunctionsX][jj]); 												
						_del[2]=((_p2[(ii+1)%_nJunctionsX][jj][(w+_dwn[ii][(jj+1)%_nJunctionsY])%n])*(1.0-_fractional[ii][(jj+1)%_nJunctionsY])+(_p2[(ii+1)%_nJunctionsX][jj][(w+_ddup[ii][(jj+1)%_nJunctionsY])%n])*_fractional[ii][(jj+1)%_nJunctionsY]);  						
						_del[3]=((_p3[((ii+_nJunctionsX)-1)%_nJunctionsX][jj][(w+_dwn[ii][jj])%n]) *(1.0-_fractional[ii][jj])+(_p3[((ii+_nJunctionsX)-1)%_nJunctionsX][jj][(w+_ddup[ii][jj])%n])*_fractional[ii][jj]) ;
									
						 _p[ii][jj]=  _del[0]+_del[1]+_del[2]+_del[3];
					
                        
                        
                        

						ddiv=0.5;						
						//if we are at the junction selected for the input, add input and set ddiv 0.4
						if((ii==(int)in_x && jj== (int)in_y ) )
						{
							_p[ii][jj]+=_in;
							
							ddiv=0.4;
						}

						//junction result											
						_p[ii][jj]*=ddiv;   //normalize  -  attenuate junction
						

// ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

						// filtering and ring memory 
						//s=0 n=1 e= 2 w=3
						int _wn=w+n;
						_p0[ii][jj][(_wn-1)%n]=((( _damping*_p[ii][jj] -   _del[1]   )   )*(1-_cutoff)+_cutoff*(_p0[ii][jj][(_wn-2)%n]));
						_p1[ii][jj][(_wn-1)%n]=((( _damping*_p[ii][jj] -_del[0]  ))*(1-_cutoff)+_cutoff*(		 _p1[ii][jj][(_wn-2)%n]));
						_p2[ii][jj][(_wn-1)%n]=((( _damping*_p[ii][jj] -_del[3]  ))*(1-_cutoff)+_cutoff*(		 _p2[ii][jj][(_wn-2)%n]));
						_p3[ii][jj][(_wn-1)%n]=(((  _damping*_p[ii][jj] -_del[2]   ))*(1-_cutoff)+_cutoff*(     _p3[ii][jj][(_wn-2)%n]));

			
					}
				}
			
			//OUTPUT SAMPLES and control signals
				
		            
			// xy are the coordinates given for reading from junctions, xold and yold are for passing with an envelope from one to another.
			//TODO: implement stereo output for supercollider, till then return the selected junction for output
			float _out1=(	_p[_x][_y]*envch+ (1-envch)*_p[_xOld][_yOld]	);
			float _out2=(	_p[_y][_x]*envch+ (1-envch)*_p[_yOld][_xOld]	);
			
		
		
        
        
			w++;
			w%=n;
			
			envch=envch        +envd;
			envch=envch >=1 ? 1:envch;
			// result
			return(_p[_x][_y]);
       
			}
		















};


// Functions external to the UGen:
extern "C"
{
	// Definition for the audio calculation function
	void PMWave_next(PMWave *unit, int numSamples);

	// Definition of the constructor
	void PMWave_Ctor(PMWave *unit);
};




//using _fclipf for std::fminf, sc_fclipf is std::min

// The constructor, with reference to unit or custom struct
void PMWave_Ctor(PMWave* unit)
{	

	
	
	//set defaults 
		

		unit->ddiv=0.5;
		unit->w=0;						                       
		unit-> envch=0;
        unit->in_x=0; // where to write x 
        unit->in_y=0; //  where to write y 
        unit->envd=0.03; 
		unit->_x=2; //where to read x
        unit->_y=2; //where to read y
		unit->_xOld=0;
		unit->_yOld=1;

        unit->_randAmt1=0.01;
		unit->_randAmt2=0.03;


	


	
	// 0			1				2			3			4			 5	6		7				8				9					10
	//arg in = 0.0, damping=0.5, distance=0.5,speed=0.2 , ,cutoff=0.5,pAmt1,pAmt2, probTrig=0.0, nJunctionsX = 3.0, nJunctionsY = 3.0, delaySamples = 100
	//get constructor arguments
	
	unit->n=1000;// size of the delay in samples, set it once in constructor.
	//delay time
	unit->_time=unit->n * unit->_fclipf(ZIN0(2),0.0f,1.0f);
	//speed from one delay time to another
	unit->_speed=unit->_fclipf(ZIN0(3),unit->getInvSampleRate(),1.0f);
	unit->_damping=unit->_fclipf(ZIN0(1),0.0f,1.0f);
	unit->_randAmt1=unit->_fclipf(ZIN0(5),0.0f,1.0f);
	unit->_randAmt2=unit->_fclipf(ZIN0(6),0.0f,1.0f);
	unit->_cutoff=unit->_fclipf(ZIN0(4),0.0f,1.0f);
	//minimum size 2x2
	unit->_nJunctionsX=3;//std::abs((int)std::max((int)ZIN0(8),2));
	unit->_nJunctionsY=3;//std::abs((int)std::max((int)ZIN0(9),2));

	
for(int i=0;i<4;i++){unit->_del[i]=0;}
    
    
for(int i=0;i<unit->_nJunctionsX;i++)
		{
			for(int j=0;j<unit->_nJunctionsY;j++)
			{
					for(int _z=0;_z<unit->n;_z++)
					{
						unit->_p0[i][j][_z]=0;
						unit->_p1[i][j][_z]=0;
						unit->_p2[i][j][_z]=0;
						unit->_p3[i][j][_z]=0;
					}
					unit->_currentDistance[i][j]=unit->n*0.5;
					unit->_p[i][j]=0;
					unit->_fractional[i][j]=0;
					unit->_ddup[i][j]=0;
					unit->_dwn[i][j]=0;





					unit->_rand2[i][j]=((rand() / (float)RAND_MAX)-0.5);
					//std::srand(std::time(nullptr));
					unit->_rand1[i][j]=((rand() / (float)RAND_MAX)-0.5);

					unit->_meanLength[i][j] = unit->_fclipf((unit->_time+(2*unit->_rand1[i][j]*unit->_randAmt1)), 1,(float)unit->n) ;
					
					unit->sens[i][j]= unit->_fclipf(unit->_speed+(2*unit->_rand2[i][j]*unit->_randAmt2),unit->getInvSampleRate(),1.0f) ; 
					unit->rsens[i][j]=unit->sens[i][j];
                   // std::cout< <_meanLength[i][j]< <"\n";
			}
			
		}
	

		unit->_resetRandom();
		unit->_updateRandAmt1(unit->_randAmt1);	
		unit->_updateRandAmt2(unit->_randAmt2);
	// Specify which function is used for audio calculation
	
	unit->_updateTimeMeanLength(unit->_time);
	unit->_updateSpeed(unit->_speed);
	
SETCALC(PMWave_next);
	// Calculate one sample
	PMWave_next(unit, 1);	
	
	
   
}



void PMWave_next(PMWave *unit, int numSamples)
{
		// Pointer to output buffer
	float *out = ZOUT(0);
	// Pointer to the input buffer
	float *in = ZIN(0);
	
	// 0			1				2			3			4			 5	6		7			
	//arg in = 0.0, damping=0.5, distance=0.5,speed=0.2  ,cutoff=0.5,pAmt1,pAmt2, probTrig=0.0
	unit->_setDamping(ZIN0(1));
	unit->_setCutoff(ZIN0(4));

	if(std::abs(ZIN0(2)*unit->n-unit->_time)>0.00001)unit->_updateTimeMeanLength(ZIN0(2));
	if(unit->_fclipf(ZIN0(3),0,1)!=unit->_speed)unit->_updateSpeed(ZIN0(3));
	if(unit->_fclipf(ZIN0(5),0,1)!=unit->_randAmt1)unit->_updateRandAmt1(ZIN0(5));	
	if(unit->_fclipf(ZIN0(6),0,1)!=unit->_randAmt2)unit->_updateRandAmt2(ZIN0(6));	
	// Obtain the first argument
	//float thres = ZIN0(1);

	// Use LOOP macro to iterate and ZXP to advance pointers
	LOOP(numSamples,
		ZXP(out) = unit->_render(ZXP(in));
	)
}
// Macro used by the host when plugin is loaded, needs naming conventions
PluginLoad(PMWave)
{
	// inTable is defined in the macro, 
	ft = inTable;
	
	
    // Register UGen
	DefineSimpleUnit(PMWave);
}
