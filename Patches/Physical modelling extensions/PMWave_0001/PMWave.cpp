

#include "PMWave.h"

//using _fclipf for std::fminf, sc_fclipf is std::min

// The constructor, with reference to unit or custom struct
void PMWave_Ctor(PMWave* unit)
{	
	// 0			1				2			3			4			 5	6		7				8				9					10
	//arg in = 0.0, damping=0.5, distance=0.5,speed=0.2 , ,cutoff=0.5,pAmt1,pAmt2, probTrig=0.0, nJunctionsX = 3.0, nJunctionsY = 3.0, delaySamples = 100


	//get constructor arguments
	
	unit->n=ZIN0(10);// size of the delay in samples, set it once in constructor.
	//delay time
	unit->_time=unit->n * unit->_fclipf(ZIN0(2),0.0f,1.0f);
	//speed from one delay time to another
	unit->_speed=unit->_fclipf(ZIN0(3),unit->getInvSampleRate(),1.0f);
	unit->_damping=unit->_fclipf(ZIN0(1),0.0f,1.0f);
	unit->_randAmt1=unit->_fclipf(ZIN0(5),0.0f,1.0f);
	unit->_randAmt2=unit->_fclipf(ZIN0(6),0.0f,1.0f);

	//minimum size 2x2
	unit->_nJunctionsX=(uint)std::min((int)ZIN0(8),2);
	unit->_nJunctionsY=(uint)std::min((int)ZIN0(9),2);

	//initialize global vectors
	unit->_p0=std::vector<std::vector<std::vector<float> > >(unit->_nJunctionsX,std::vector<std::vector<float> >(unit->_nJunctionsY,std::vector<float>(unit->n,0)));
	unit->_p1=std::vector<std::vector<std::vector<float> > >(unit->_nJunctionsX,std::vector<std::vector<float> >(unit->_nJunctionsY,std::vector<float>(unit->n,0)));
	unit->_p2=std::vector<std::vector<std::vector<float> > >(unit->_nJunctionsX,std::vector<std::vector<float> >(unit->_nJunctionsY,std::vector<float>(unit->n,0)));
	unit->_p3=std::vector<std::vector<std::vector<float> > >(unit->_nJunctionsX,std::vector<std::vector<float> >(unit->_nJunctionsY,std::vector<float>(unit->n,0)));

	unit->_currentDistance=std::vector<std::vector<float> >(unit->_nJunctionsX,std::vector<float>(unit->_nJunctionsY,0.5*unit->_time));
	
	unit->_meanLength=std::vector<std::vector<float> >(unit->_nJunctionsX,std::vector<float>(unit->_nJunctionsY,0));

	unit->_rand1=std::vector<std::vector<float> >(unit->_nJunctionsX,std::vector<float>(unit->_nJunctionsY,0));
	unit->_rand2=std::vector<std::vector<float> >(unit->_nJunctionsX,std::vector<float>(unit->_nJunctionsY,0));

	std::srand(std::time(nullptr));
	
	unit->sens=std::vector<std::vector<float> >(unit->_nJunctionsX,std::vector<float>(unit->_nJunctionsY,0));
	unit->rsens=std::vector<std::vector<float> >(unit->_nJunctionsX,std::vector<float>(unit->_nJunctionsY,0));

	

                     
    
   

    
for(auto i=0;i<unit->_nJunctionsX;i++)
		{
			for(auto j=0;j<unit->_nJunctionsY;j++)
			{
					unit->_rand2[i][j]=((rand() / (float)RAND_MAX)-0.5);
					std::srand(std::time(nullptr));
					unit->_rand1[i][j]=((rand() / (float)RAND_MAX)-0.5);

					unit->_meanLength[i][j] = unit->_fclipf((unit->_time+(2*unit->_rand1[i][j]*unit->_randAmt1)), 0.000001f,(float)unit->n) ;
					
					unit->sens[i][j]=     unit->_fclipf(unit->_speed+(2*unit->_rand2[i][j]*unit->_randAmt2),unit->getInvSampleRate(),1.0f) ; 
					unit->rsens[i][j]=unit->sens[i][j];
                   // std::cout< <_meanLength[i][j]< <"\n";
			}
			
		}
	// Specify which function is used for audio calculation
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
	
	// 0			1				2			3			4			 5	6		7				8				9					10
	//arg in = 0.0, damping=0.5, distance=0.5,speed=0.2 , ,cutoff=0.5,pAmt1,pAmt2, probTrig=0.0, nJunctionsX = 3.0, nJunctionsY = 3.0, delaySamples = 100
	unit->_setDamping(ZIN0(1));
	unit->_setCutoff(ZIN0(4));

	if(ZIN0(2)*unit->n!=unit->_time)unit->_updateTimeMeanLength(ZIN0(2));
	if(unit->_fclipf(ZIN0(3),0,1)!=unit->_speed)unit->_updateSpeed(ZIN0(3));
	if(unit->_fclipf(ZIN0(5),0,1)!=unit->_randAmt1)unit->_updateRandAmt1(ZIN0(5));	
	if(unit->_fclipf(ZIN0(6),0,1)!=unit->_randAmt2)unit->_updateRandAmt1(ZIN0(6));	
	// Obtain the first argument
	//float thres = ZIN0(1);

	// Use LOOP macro to iterate and ZXP to advance pointers
	LOOP(numSamples,
		ZXP(out) = unit->_render(ZXP(in));
	)
}

 void PMWave::_updateTimeMeanLength(const float _inTime)
 {
	

	_time=n * _fclipf(_inTime,0,1);

	 for(auto i=0;i<_nJunctionsX;i++)	
	{
		for(auto j=0;j<_nJunctionsY;j++)
		{	
			_meanLength[i][j] = _fclipf((_time+(2*_rand1[i][j]*_randAmt1)),0,n );
		}
					
	}
	 
 }

void PMWave::_updateSpeed(const float _inSpeed)
{
	_speed=_fclipf(_inSpeed,0,1);
    for(auto i=0;i<_nJunctionsX;i++)
    {
        for(auto j=0;j<_nJunctionsY;j++)
        {
			sens[i][j]= _fclipf(_speed+(2.0f*_rand2[i][j]*_randAmt2) ,getInvSampleRate() ,1.0f) ; 
			rsens[i][j]=sens[i][j];  
		
		}
        			
    }  

}



void PMWave::_updateRandAmt1(const float _randAmt)
{
			_randAmt1=_randAmt;
        		
        	for(auto i=0;i<_nJunctionsX;i++)	
			{
				for(auto j=0;j<_nJunctionsY;j++)
				{
						_meanLength[i][j] = _fclipf(_time+(2*_rand1[i][j]*_randAmt1),0,(float)n );
				}
			}
        		
        		
}

void PMWave::_updateRandAmt2(const float _randAmt)
{
			_randAmt2=_randAmt;
        		for(auto i=0;i<_nJunctionsX;i++)
        		{
        			for(auto j=0;j<_nJunctionsY;j++)
        		{
					sens[i][j]=     _fclipf(_speed+(2*_rand2[i][j]*_randAmt2),getInvSampleRate(),1.0f ) ; 
					rsens[i][j]=sens[i][j];
				}
        			
        		}  
        		
        		
}
void PMWave::_setDamping(const float _damp){_damping=_damp;}
void PMWave::_setCutoff(const float _cut){_cutoff=_cut;}

void PMWave::_resetRandom(){
        	//((rand() / (float)RAND_MAX)-0.5f)
        		for(auto i=0;i<_nJunctionsX;i++)
        		{
        			for(auto j=0;j<_nJunctionsY;j++)
					{
						_rand1[i][j]=  ((rand() / (float)RAND_MAX)-0.5f)  ; 
						_rand2[i][j]=  ((rand() / (float)RAND_MAX)-0.5f)  ; 
						sens[i][j]=     _fclipf(_speed+(2.0f*_rand2[i][j]*_randAmt2) ,getInvSampleRate(),1.0f) ; 
						rsens[i][j]=sens[i][j];
						_meanLength[i][j] = _fclipf(_time+(2*_rand1[i][j]*_randAmt1),0,(float)n) ;
				 
					 }
        			
        		}  
        		
        	}




 float PMWave::_render(const float _in){     
       
	  
       
		
        
        
       // auto _p=std::vector<std::vector<float>(_nJunctionsY,0)>(_nJunctionsX,0);
		std::vector<std::vector<int> > _p(_nJunctionsX, std::vector<int>(_nJunctionsY,0));

        //TODO: substitute iteration indices 
				//MAIN LOOP on plate
				for(auto ii=0;ii<_nJunctionsX;ii++)
				{
					for(auto jj=0;jj<_nJunctionsY;jj++)   
					{
					
                        
                       
                        //s=0 n=1 e= 2 w=3
                        
                        
                        
                        //RANDOMIZED GLISSANDOS BETWEEN JUNCTIONS
						
						//loc
						
                        //dsens[ii][jj]=std::abs(_meanLength[ii][jj]  -dly[ii][jj]);	//distance between value to reach and current value
						float dsens=std::abs(_meanLength[ii][jj]  -_currentDistance[ii][jj]);

				        sens[ii][jj]= dsens<sens[ii][jj]? dsens: rsens[ii][jj];  
                        _currentDistance[ii][jj]+=_currentDistance[ii][jj]<_meanLength[ii][jj] ? (sens[ii][jj]):  ( _currentDistance[ii][jj]>_meanLength[ii][jj] ? (-sens[ii][jj]):0);
						
						
                        std::vector<float> _del;
                        
						//interpolation and junction calculation
						
						auto _dwn=(int)_currentDistance[ii][jj];
						auto _ddup=_dwn+1;
						auto _fractional=fmodf(_currentDistance[ii][jj],1.0f);

						_del.push_back((  _p0[ii][((jj-1)+_nJunctionsY)%_nJunctionsY][(w+_dwn)%n]  )*(1.0-_fractional) +(_p0[ii][((jj-1)+_nJunctionsY)%_nJunctionsY][(w+_ddup)%n] )*_fractional);	
                        
						//save these for last input
						auto _tdw=_dwn;
						auto _tup=_ddup;
						auto _tfractional=_fractional;

						_dwn=(int)_currentDistance[(ii+1)%_nJunctionsX][jj];
						_ddup=_dwn+1.0f;
						_fractional=fmodf(_currentDistance[(ii+1)%_nJunctionsX][jj],1.0f);
						
						_del.push_back((_p1[ii][(jj+1)%_nJunctionsY][(w+_dwn)%n]  )*(1-_fractional)+   (_p1[ii][(jj+1)%_nJunctionsY][(w+_ddup)%n]  )*_fractional); 
						
						_dwn=(int)_currentDistance[ii][(jj+1)%_nJunctionsY];
						_ddup=_dwn+1;
						_fractional=fmodf(_currentDistance[ii][(jj+1)%_nJunctionsY],1.0f);
						_del.push_back((_p2[(ii+1)%_nJunctionsX][jj][(w+_dwn)%n])*(1.0-_fractional)+(_p2[(ii+1)%_nJunctionsX][jj][(w+_ddup)%n])*_fractional);  
						
						
						_del.push_back((_p3[((ii+_nJunctionsX)-1)%_nJunctionsX][jj][(w+_tdw)%n]) *(1.0-_tfractional)+(_p3[((ii+_nJunctionsX)-1)%_nJunctionsX][jj][(w+_tup)%n])*_tfractional) ;
						
						
						//loc
						 _p[ii][jj]=  std::accumulate(_del.begin(),_del.end(),0);
					
                        
                        
                        
						//loc
						ddiv=0.5;
						//if we are at the junction selected for the input, add input and set ddiv 0.4
						if((ii==(int)in_x && jj== (int)in_y ) )
						{
							_p[ii][jj]+=_in;
							
							ddiv=0.4;
						}
                        												
						_p[ii][jj]*=ddiv;   //normalize  -  divide junction value by number of inputs to junction
						
						if(_del.size()!=4){_del=std::vector<float>(4,0);}


						// filtering and ring memory 
						//s=0 n=1 e= 2 w=3
						auto _wn=w+n;
						_p0[ii][jj][(_wn-1)%n]=(( _damping*_p[ii][jj] -   _del[1]   )   )*(1-_cutoff)+_cutoff*(_p0[ii][jj][(_wn-2)%n]);
						_p1[ii][jj][(_wn-1)%n]=(( _damping*_p[ii][jj] -_del[0]  ))*(1-_cutoff)+_cutoff*(		 _p1[ii][jj][(_wn-2)%n]);
						_p2[ii][jj][(_wn-1)%n]=(( _damping*_p[ii][jj] -_del[3]  ))*(1-_cutoff)+_cutoff*(		 _p2[ii][jj][(_wn-2)%n]);
						_p3[ii][jj][(_wn-1)%n]=((  _damping*_p[ii][jj] -_del[2]   ))*(1-_cutoff)+_cutoff*(     _p3[ii][jj][(_wn-2)%n]);

			
					}
				}
			
			//OUTPUT SAMPLES and control signals
				
		            
			// xy are the coordinates given for reading from junctions, xold and yold are for passing with an envelope from one to another.
			auto _out1=(	_p[_x][_y]*envch+ (1-envch)*_p[_xOld][_yOld]	);
			auto _out2=(	_p[_y][_x]*envch+ (1-envch)*_p[_yOld][_xOld]	);
			
		
		
        
        
			w++;
			w%=n;
			
			envch=envch        +envd;
			envch=envch >=1 ? 1:envch;

			return(_out1);
       
			}
		


// Macro used by the host when plugin is loaded, needs naming conventions
PluginLoad(PMWave)
{
	// inTable is defined in the macro, 
	ft = inTable;

    // Register UGen
	DefineSimpleUnit(PMWave);
}
