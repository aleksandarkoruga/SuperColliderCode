
((0..11)%4)



[[0.7,0.08,0.0,0.0],[0.0,0.0,0.0,0.0],[0.0,0.0,0.0,0.0]].flat


(SynthDef(\pend,
{
		arg nnl=0.01,damp=0.1, dt=0.001,stif= 0.3;

	var lB=LocalBuf.newFrom([0.7,0.08,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]);

	//p v a
	var p=[[0,0,0,0],[0,0,0,0],[0,0,0,0]];



	var m=1.0;
	var directionL,directionR;
	var mL,mR;

		12.do({|i|
			var x= (i/4).floor;
			var y= i%4;

				p[x][y]=Duty.ar(SampleDur.ir,0.0, Dbufrd(lB,i) );

		})	;


	//mL=p[0].pow(2.0).sum.sqrt;
	//mR=(p[0]-[1.0,0.0,0.0,0.0]).pow(2.0).sum.sqrt;
	directionL= p[0];//mL;
	directionR= (p[0]-[10.0,0.0,0.0,0.0]);///mR;

	p[2]=p[2] -1.0*((( (directionL ) )*stif)/m)- ((((directionR  )  )*stif)/m)-nnl*((8.59*(p[2]-p[2].at([1,2,3,0]))).cos) ;

	p[1]=(p[1]+(p[2]*dt))*damp;


	p[0]=p[0]+(p[1]*dt);
	// ;

		//p[0]=p[0]+[Dust.ar(0.01,0.001),Dust.ar(0.01,0.9),Dust.ar(0.01,0.001),Dust.ar(0.01,0.001)];
		p= 1000.0* ((p*0.001).tanh);


	12.do({|i|
			var x= (i/4).floor;
			var y= i%4;

			Duty.ar(SampleDur.ir,0.0, Dbufwr(p[x][y],lB,i) );
		})	;



		Out.ar(0,	LeakDC.ar(Mix.ar(p[0].tanh.pow(2)).sqrt.poll)+LeakDC.ar(100.0*p[0][0]).tanh);





}).add;)
s.scope
y=Synth(\pend);
y.set(\nnl,0.2,\stif,0.9,\dt,0.002,\damp,0.99)
0.5.sinh
Complex.new(-0.8,0.2).sin