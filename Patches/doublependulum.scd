//Plot version
(
f={
	var q=[[0.0,0.0],[1.01,-0.001],[0.0,0.0]];
	var rot=0.0;
var timeStep=
{
	arg dT= 0.01,q=[[0.0,0.0],[0.0,0.0],[0.0,0.0]];
	var pt=q[0],pt1=q[1],pt2=q[2];



	var pt2F={
	|m1=0.2,m2=10.01,l1=3.0,l2=1.0,phi=0.0,phi1=0.0,theta=0.0,theta1=0.0|
	var phi2,theta2;
	var dA=phi-theta;

	phi2= -1.0*(m2*( (l2*theta1.pow(2.0))+(l1*phi1.pow(2)*(dA).cos) )*dA.sin)/(l1*(m1+(m2*dA.sin.pow(2))));
	theta2= (((m1+m2)*(l1*phi1.pow(2.0))+l2*m2*dA.cos*theta1.pow(2))*(dA.sin))/(l2*(m1+(m2*(dA.sin.pow(2)))));

	[phi2,theta2];
};
	pt2=pt2F.value(phi:pt[0],theta:pt[1],phi1:pt1[0],theta1:pt1[1]);
	pt1=(pt1+(pt2.postln*dT));
	pt=pt+(pt1*dT);

	[pt,pt1,pt2];
};
10000.collect({

q=timeStep.value(0.01,q+[[0.0,0.94*(rot).sin],[0.0,0.0],[0.0,0.0]]).wrap2(2pi);
rot=(q[0][1]+rot).wrap2(2pi);
q;
});

};
a=f.value;
b=a.collect({|item|item[0]=item[0].cos; item.flatten});
b.flop.plot

)


// ///////////////////////////////////////////////////////////
//double pendulum without gravity, coupled to a standard map
//https://www.12000.org/my_notes/double_pendulum/main.html
(
SynthDef(\pend2,{
	|m1=1.0,m2=1.0,l1=1.0,l2=1.0,k=0.1,t=1.0,freq=100.0,damp=0.999|
	var q=[0.0,0.0,10.01,-0.001,0.0,0.0];
	var buf=LocalBuf.newFrom([0.0,0.0,-10.1,-1.0,0.0,0.0]);
	var bufR=LocalBuf.new(1);
	var rot=0.0;


var timeStep=
{
	arg dT= SampleDur.ir,q=[0.0,0.0,0.0,0.0,0.0,0.0],m1,m2,l1,l2,damp;
	var pt=[q[0],q[1]],pt1=[q[2],q[3]],pt2=[q[4],q[5]];



	var pt2F={
	|m1=0.000002,m2=0.0000001,l1=0.000001,l2=0.00001,phi=0.0,phi1=0.0,theta=0.0,theta1=0.0|
	var phi2,theta2;
	var dA=phi-theta;

	phi2= -1.0*(m2*( (l2*theta1.pow(2.0))+(l1*phi1.pow(2)*(dA).cos) )*dA.sin)/(l1*(m1+(m2*dA.sin.pow(2))));
	theta2= (((m1+m2)*(l1*phi1.pow(2.0))+l2*m2*dA.cos*theta1.pow(2))*(dA.sin))/(l2*(m1+(m2*(dA.sin.pow(2)))));

	[phi2,theta2];
};
	pt2=pt2F.value(phi:pt[0],theta:pt[1],phi1:pt1[0],theta1:pt1[1],m1:m1,m2:m2,l1:l1,l2:l2);





	pt1=((pt1+(pt2.postln*dT)))*damp;
	pt=pt+(pt1*dT);

	[pt[0],pt[1],pt1[0],pt1[1],pt2[0],pt2[1]].wrap2(2pi);
};




q= 6.collect({|i| Duty.ar(SampleDur.ir,0.0,Dbufrd(buf,i)) });
rot=	Duty.ar(SampleDur.ir,0.0,Dbufrd(bufR,0)) ;

q=
	Duty.ar(SampleDur.ir,0,timeStep.value(t*SampleDur.ir,q+[[0.0,k*(rot+freq).sin],[0.0,0.0],[0.0,0.0]],m1:m1,m2:m2,l1:l1,l2:l2,damp:damp).wrap2(2pi));

	rot=(q[0][1]+rot).mod(2pi);

	q= 6.collect({|i| Duty.ar(SampleDur.ir,0.0,Dbufwr(q[i],buf,i)) });
	rot=Duty.ar(SampleDur.ir,0.0,Dbufwr(rot,bufR,0)) ;



	Out.ar(0,LeakDC.ar((q[0].sin).tanh));

}).add;
)
y=Synth(\pend2)
y.set(\m1,0.1,\m2,0.1,\l1,0.3,\l2,0.6,\k,0.971635*0.5,\t,1.0,\freq,500.0,\damp,0.95)

s.scope

//


(100.collect({
a= (a+(0.1*pi)).mod(1.0).postln;
if(a<(0.1*pi),{1.postln},{0.postln})
}
)).integrate.histo(100,0,100).reject(_==0)



a = SpectrogramWindow.new;
a.start