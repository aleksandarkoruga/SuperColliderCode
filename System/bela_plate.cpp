#include <Bela.h>
#include <algorithm>
#include <stdlib.h>
#include <math.h>
#include <time.h>  
#include <cmath>
#include <iostream>
#include <OSCServer.h>
#include <OSCClient.h>
# include <math_neon.h>



OSCServer oscServer;
OSCClient oscClient;


int localPort = 7562;
int remotePort = 7563;
const char* remoteIp = "255.255.255.255";



int _nJunctionsX=3;
int _nJunctionsY=3;
int n=1000;
						
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

float getInvSampleRate(BelaContext *context){return (float) (  1.0/context->audioSampleRate);}


float _fclipf(const float _in,const float _min,const float _max)
{
	return fminf(fmaxf(_in,_min),_max);
}


void _updateSpeed(const float _inSpeed,BelaContext *context)
{
	_speed=_fclipf(_inSpeed,0,1);
    for(int i=0;i<_nJunctionsX;i++)
    {
        for(int j=0;j<_nJunctionsY;j++)
        {
			sens[i][j]= _fclipf(_speed+(2.0f*_rand2[i][j]*_randAmt2) ,getInvSampleRate(context) ,1.0f) ; 
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

void _updateRandAmt2(const float _randAmt,BelaContext *context)
{
			_randAmt2=_randAmt;
        		for(int i=0;i<_nJunctionsX;i++)
        		{
        			for(int j=0;j<_nJunctionsY;j++)
        		{
					sens[i][j]=     _fclipf(_speed+(2*_rand2[i][j]*_randAmt2),getInvSampleRate(context),1.0f ) ; 
					rsens[i][j]=sens[i][j];
				}
        			
        		}  
        		
        		
}
void _setDamping(const float _damp){_damping=_damp;
	
	//_updateRandAmt1(_randAmt1);
	
	
	
}
void _setCutoff(const float _cut){_cutoff=_cut;}

void _resetRandom(BelaContext *context){
        	//((rand() / (float)RAND_MAX)-0.5f)
        		for(int i=0;i<_nJunctionsX;i++)
        		{
        			for(int j=0;j<_nJunctionsY;j++)
					{
						_rand1[i][j]=  ((rand() / (float)RAND_MAX)-0.5f)  ; 
						_rand2[i][j]=  ((rand() / (float)RAND_MAX)-0.5f)  ; 
						sens[i][j]=     _fclipf(_speed+(2.0f*_rand2[i][j]*_randAmt2) ,getInvSampleRate(context),1.0f) ; 
						rsens[i][j]=sens[i][j];
						_meanLength[i][j] = _fclipf(_time+(2*_rand1[i][j]*_randAmt1),1,(float)n) ;
				 
					 }
        			
        		}  
        		
        	}






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


bool setup(BelaContext *context, void *userData)
{
		
		oscServer.setup(localPort);
    	oscClient.setup(remotePort, remoteIp);
		srand (time(NULL));
		oscClient.sendMessageNow(oscClient.newMessage.to("/osc-setup").end());
		
	
	//set defaults 
		

		ddiv=0.5;
		w=0;						                       
		envch=0;
        in_x=1; // where to write x 
        in_y=2; //  where to write y 
        envd=0.03; 
		_x=2; //where to read x
        _y=0; //where to read y
		_xOld=0;
		_yOld=1;

         _randAmt1=0.01;
		 _randAmt2=0.03;


	


	
	
	
	 n=1000;// size of the delay in samples, set it once in constructor.
	//delay time
	 _time= n *  _fclipf(0.5,0.0f,1.0f);
	//speed from one delay time to another
	 _speed= _fclipf(0.5, getInvSampleRate(context),1.0f);
	 _damping= _fclipf(0.5,0.0f,1.0f);
	 _randAmt1= _fclipf(0.001,0.0f,1.0f);
	 _randAmt2= _fclipf(0.001,0.0f,1.0f);
	 _cutoff= _fclipf(0.2,0.0f,1.0f);

	

	
for(int i=0;i<4;i++){ _del[i]=0;}
    
    
for(int i=0;i< _nJunctionsX;i++)
		{
			for(int j=0;j< _nJunctionsY;j++)
			{
					for(int _z=0;_z< n;_z++)
					{
						 _p0[i][j][_z]=0;
						 _p1[i][j][_z]=0;
						 _p2[i][j][_z]=0;
						 _p3[i][j][_z]=0;
					}
					 _currentDistance[i][j]= n*0.5;
					 _p[i][j]=0;
					 _fractional[i][j]=0;
					 _ddup[i][j]=0;
					 _dwn[i][j]=0;





					 _rand2[i][j]=((rand() / (float)RAND_MAX)-0.5);
					//std::srand(std::time(nullptr));
					 _rand1[i][j]=((rand() / (float)RAND_MAX)-0.5);

					 _meanLength[i][j] =  _fclipf(( _time+(2* _rand1[i][j]* _randAmt1)), 1,(float) n) ;
					
					 sens[i][j]=  _fclipf( _speed+(2* _rand2[i][j]* _randAmt2), getInvSampleRate(context),1.0f) ; 
					 rsens[i][j]= sens[i][j];
                   // std::cout< <_meanLength[i][j]< <"\n";
			}
			
		}
	

		 _resetRandom(context);
		 _updateRandAmt1( _randAmt1);	
		 _updateRandAmt2( _randAmt2,context);

	 _updateTimeMeanLength( _time);
	 _updateSpeed( _speed,context);
	
	
	
	return true;
}



 void _renderBela(const float _inL,const float _inR,BelaContext *context, int q){     
       
  
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
						_del[1]=((_p1[ii][(jj+1)%_nJunctionsY][(w+_dwn[(ii+1)%_nJunctionsX][jj])%n]  )*(1.0-_fractional[(ii+1)%_nJunctionsX][jj])+   (_p1[ii][(jj+1)%_nJunctionsY][(w+_ddup[(ii+1)%_nJunctionsX][jj])%n]  )*_fractional[(ii+1)%_nJunctionsX][jj]); 												
						_del[2]=((_p2[(ii+1)%_nJunctionsX][jj][(w+_dwn[ii][(jj+1)%_nJunctionsY])%n])*(1.0-_fractional[ii][(jj+1)%_nJunctionsY])+(_p2[(ii+1)%_nJunctionsX][jj][(w+_ddup[ii][(jj+1)%_nJunctionsY])%n])*_fractional[ii][(jj+1)%_nJunctionsY]);  						
						_del[3]=((_p3[((ii+_nJunctionsX)-1)%_nJunctionsX][jj][(w+_dwn[ii][jj])%n]) *(1.0-_fractional[ii][jj])+(_p3[((ii+_nJunctionsX)-1)%_nJunctionsX][jj][(w+_ddup[ii][jj])%n])*_fractional[ii][jj]) ;
									
						 _p[ii][jj]=  _del[0]+_del[1]+_del[2]+_del[3];
					
                        
                        
                        

						ddiv=0.5;						
						//if we are at the junction selected for the input, add input and set ddiv 0.4
						if((ii==(int)in_x && jj== (int)in_y ) )
						{
							_p[ii][jj]+=_inR;
							
							ddiv=0.4;
						}
							if((ii==(int)in_y && jj== (int)in_x ) )
						{
							_p[ii][jj]+=_inL;
							
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
			float out_L=(	_p[_x][_y]*envch+ (1-envch)*_p[_xOld][_yOld]	);
			float out_R=(	_p[_y][_x]*envch+ (1-envch)*_p[_yOld][_xOld]	);
			
		audioWrite(context, q, 0,  tanhf_neon(out_L*2.0));
		audioWrite(context, q, 1,  tanhf_neon(out_R*2.0) );
		
        
        
			w++;
			w%=n;
			
			envch=envch        +envd;
			envch=envch >=1 ? 1:envch;
			// result
		//	return(_p[_x][_y]);
       
			}







void _setX(float _inX)
{
	_x=(int)_inX%2;
}
void _setY(float _inY)
{
	_y=(int)_inY%2;
}

void render(BelaContext *context, void *userData)
{


auto oldArg=-1;
// receive OSC messages, parse them, and send back an acknowledgment
    while (oscServer.messageWaiting()){
//int count = parseMessage(oscServer.popMessage());
        
        oscpkt::Message msg;
        msg=oscServer.popMessage();
        
        int intArg;
    	float floatArg;
        if (msg.match("/belaReverb").popInt32(intArg).popFloat(floatArg).isOkNoMoreArgs()){
        
        
		if(oldArg!=intArg)
        switch(intArg)
        {
        	case 0: {
        	
        		if(fabsf_neon(floatArg-_damping)>0.00001)
        		_setDamping(floatArg);
        		
        	} break;   
        	case 1: {
        			if(fabsf_neon(floatArg*n-_time)>0.00001)
        	_updateTimeMeanLength(floatArg);
        	 
        		
        	} break;
        	case 2: {
        			if(fabsf_neon(floatArg-_cutoff)>0.00001)
        	 _setCutoff(floatArg);
        		
        	} break;
        	case 3: {
        			if(fabsf_neon(floatArg-_speed)>0.00001)
        	_updateSpeed(floatArg,context);
        	  
        		
        	} break;
        	case 4: {
        		if(fabsf_neon(floatArg-_randAmt1)>0.00001)
        	  _updateRandAmt1(floatArg);	

        		
        	} break;
        	case 5: {
        		if(fabsf_neon(floatArg-_randAmt2)>0.00001)
        	  _updateRandAmt2(floatArg,context);
        		
        	} break;
       		case 6: {
        	
        	  _resetRandom(context);
        		
        	} break;
        	
       		case 7: {
        	
        	  _setX(floatArg);
        		
        	} break;
        		case 8: {
        	
        	  _setY(floatArg);
        		
        	} break;
        	default:  break;
        }
        oldArg=intArg;
        
    }
        
        
        
}



    for(unsigned int q=0;q<context->audioFrames;q++){
				
				
				//INPUT
								
	float		in1=  (audioRead(context,q,0));
	float in2=audioRead(context,q,1);
     _renderBela(in1,in2,context,q);
     
     
       
    }




}

void cleanup(BelaContext *context, void *userData)
{

}


