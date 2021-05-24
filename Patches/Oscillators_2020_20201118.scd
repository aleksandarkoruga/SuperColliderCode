

~mandelFunc={var returnFunc={
	|freq=60.0, out=0,envRatio=0.2,fb=0.6,env2Ratio=6.0,env2Ratio1=1.0,n=4.0,totTime=0.5,curve= -8.0 ,amp=1.0,midiOffset=54,parBuf,trigBuf,resetT,length,in=28,envAmt=0.0|
	var hist1= LocalBuf(1),
	    hist2=LocalBuf(1);
	var rate=SampleRate.ir.reciprocal;
	var xyz;//,rpt;//xyz,rphitheta
	var signal, new;
	var	prev1;// = Duty.ar(rate,0,Dbufrd(hist1)); // read from buffer
	var	prev2; //= Duty.ar(rate,0,Dbufrd(hist2)); // read from buffer
	var env1;
	var env2;
	var env3;
	var envTrig;
	var attack,decay;
	var ccInput= Lag.kr( ~busK.kr(6,midiOffset));

	//[\freq,\totTime,\amp,\envRatio,\curve,\env2Ratio,\env2Ratio1,\fb,\n,envTrig]
	var sTrig=ListTrig2.kr(trigBuf,resetT,numframes:(length+1));
	var counter=PulseCount.kr(sTrig,resetT);
	var free=	FreeSelf.kr(Trig.kr(counter-length));
	var counterE;
	//counter.poll(3);
	//{if(resetT>0,{resetT=-0.1});};

	var envBuff=LocalBuf.newFrom([1.0]);
	var doneE;
	var br;
	var brc;
var chain;


	br=Duty.ar(SampleDur.ir,0,Dbufrd(envBuff));
	brc=1-((PulseCount.ar(br)-1).clip(0,1));



	freq=WrapIndex.ar(parBuf,counter*10);
	amp=WrapIndex.ar(parBuf,(counter*10)+2);
	envRatio=WrapIndex.ar(parBuf,(counter*10)+3);
	curve=WrapIndex.ar(parBuf,(counter*10)+4).wrap2(8.0);
	env2Ratio=WrapIndex.ar(parBuf,(counter*10)+5);
	env2Ratio1=WrapIndex.ar(parBuf,(counter*10)+6);
	fb=WrapIndex.ar(parBuf,(counter*10)+7);
	n=WrapIndex.ar(parBuf,(counter*10)+8);
	envTrig=(sTrig*WrapIndex.ar(parBuf,(counter*10)+9));


	counterE=PulseCount.ar(envTrig,resetT);
	totTime=WrapIndex.ar(parBuf,(counterE*10)+1);

	envRatio=envRatio*ccInput[0].linlin(0.0,127.0,0.001,1.0);
	fb=fb*ccInput[1].linexp(0.0,127.0,0.001,128.0);
	env2Ratio=env2Ratio*ccInput[2].linexp(0.0,127.0,0.01,1.0);
	env2Ratio1=env2Ratio1*ccInput[3].linexp(0.0,127.0,0.01,8.0);
	n=n*ccInput[4].linexp(0.0,127.0,0.001,24.0);


	totTime=totTime*(ccInput[5].linlin(0.0,127.0,0.001,4.0).round(0.0625));
	//totTime.clip(0.01,2.0);
	SendReply.kr(sTrig,'/trigBela',[freq,env2Ratio1]);
	{if((resetT>0.0),{resetT=-0.1;  });};

	//(in-27).poll(4,label:\voice);






	attack=(envRatio*totTime); //.poll(4,label:\att);
	decay=((1.0-envRatio)*totTime);//.poll(4,label:\dec);
	env1=EnvGen.ar( Env.perc(attack,decay,curve),(envTrig*br),doneAction:0).abs;
	doneE= Done.kr(env1) ;
	doneE=Duty.ar(SampleDur.ir,0, Dbufwr(doneE.bitOr(brc), envBuff));



	env3=EnvGen.ar( Env.asr(attack,1,decay,curve),sTrig,doneAction:0).abs;
	env2=ReplaceBadValues.ar(LFSaw.ar(-1.0*  (((attack+decay)*env2Ratio*(freq.reciprocal+(env3*(1.0-freq.reciprocal)))).clip((freq*env2Ratio1).reciprocal,1.0)).reciprocal  ,mul:0.5,add:0.5),post:0);
	env1=(((envAmt* env1)+(1.0-envAmt)).clip(0.0,1.0));
	fb=(env2*1.0)*fb;



	prev1 = Duty.ar(rate,0,Dbufrd(hist1)); // read from buffer
	prev2 = Duty.ar(rate,0,Dbufrd(hist2)); // read from buffer
//
xyz=[((prev1+(0.3333*CombC.ar(prev1.tanh,1.0,totTime.wrap(0.0,1.0)*0.01,totTime.wrap(0.0,1.0))))*0.75),((prev2+(0.3333*CombC.ar(prev2.tanh,1.0,totTime.wrap(0.0,1.0)*0.01,totTime.wrap(0.0,1.0))))*0.75),(SinOsc.ar(freq+(freq*(prev1+prev2)))+Shaper.ar(~globalMemory[7],SinOsc.ar(freq,envRatio,env2Ratio).fold(0.0,1.0)))  ];


	//sig=((sig+(0.3333*CombC.ar(sig.tanh,1.0,tEnv*0.01,tEnv)))*0.75);
			// change 128 to hear the difference
	chain=FFT(LocalBuf(128), xyz[2],wintype:1);
	chain=PV_ConformalMap(chain,xyz[0],xyz[1]);
	new= LeakDC.ar(((IFFT(chain))*fb));
	new=(new+(2.0*MoogLadder.ar(new,EnvFollow.ar( new.tanh,tCoef+(Slope.ar(new)*SampleDur.ir),freq*SinOsc.ar(freq*env1,add:2.0).abs,freq*SinOsc.ar(freq*env2).abs),SinOsc.ar(freq*env3,add:1.0).abs*0.46)))*0.3333333;
	new=env2*LeakDC.ar(((new)) ).tanh;





	//rpt=[xyz.pow(2).sum.sqrt.pow(n).fold2(1.0), atan2(xyz[2],(xyz[0..1].pow(2).sum.sqrt)),atan2(xyz[1],xyz[0])   ];


//	new=env2* ReplaceBadValues.ar([rpt[0]*(rpt[2]*n*fb).cos*(rpt[1]*n*fb).cos,
	//	rpt[0]*(rpt[2]*n*fb).sin*(rpt[1]*n*fb).cos],(((xyz[2]*freq+freq)*2pi).sin)!2,post:0);




	signal =Duty.ar(rate,0, [Dbufwr(new*(fb.neg)*xyz[0], hist1),Dbufwr(new*(fb.neg)*xyz[1],hist2)]); // write to buffers


	signal= EnvGate.new()* env1 *0.06* signal;//((  SinOsc.ar(((In.ar(in,1))*((1.0-env3)*(ReplaceBadValues.ar( [prev1,prev2],post:0)))),phase:(ReplaceBadValues.ar( [rpt[1..2]],post:0)).mod(2pi))));






	OffsetOut.ar(out
	,amp*signal.tanh); //((signal.tanh)));
	//Out.ar(20,ToggleFF.ar(CoinGate.ar(0.6,envTrig))*amp*signal.tanh);
	//Select.ar( ), [DC.ar(out),DC.ar(20.0)]).poll


};returnFunc};



// /////////BACKUP OSC MAIN

~mandelFunc={var returnFunc={
	|freq=60.0, out=0,envRatio=0.2,fb=0.6,env2Ratio=6.0,env2Ratio1=1.0,n=4.0,totTime=0.5,curve= -8.0 ,amp=1.0,midiOffset=54,parBuf,trigBuf,resetT,length,in=28,envAmt=0.0|
	var hist1= LocalBuf(1),
	    hist2=LocalBuf(1);
	var rate=SampleRate.ir.reciprocal;
	var xyz,rpt;//xyz,rphitheta
	var signal, new;
	var	prev1;// = Duty.ar(rate,0,Dbufrd(hist1)); // read from buffer
	var	prev2; //= Duty.ar(rate,0,Dbufrd(hist2)); // read from buffer
	var env1;
	var env2;
	var env3;
	var envTrig;
	var attack,decay;
	var ccInput= Lag.kr( ~busK.kr(6,midiOffset));

	//[\freq,\totTime,\amp,\envRatio,\curve,\env2Ratio,\env2Ratio1,\fb,\n,envTrig]
	var sTrig=ListTrig2.kr(trigBuf,resetT,numframes:(length+1));
	var counter=PulseCount.kr(sTrig,resetT);
	var free=	FreeSelf.kr(Trig.kr(counter-length));
	var counterE;
	//counter.poll(3);
	//{if(resetT>0,{resetT=-0.1});};

	var envBuff=LocalBuf.newFrom([1.0]);
	var doneE;
	var br;
	var brc;



	br=Duty.ar(SampleDur.ir,0,Dbufrd(envBuff));
	brc=1-((PulseCount.ar(br)-1).clip(0,1));



	freq=WrapIndex.ar(parBuf,counter*10);
	amp=WrapIndex.ar(parBuf,(counter*10)+2);
	envRatio=WrapIndex.ar(parBuf,(counter*10)+3);
	curve=WrapIndex.ar(parBuf,(counter*10)+4).wrap2(8.0);
	env2Ratio=WrapIndex.ar(parBuf,(counter*10)+5);
	env2Ratio1=WrapIndex.ar(parBuf,(counter*10)+6);
	fb=WrapIndex.ar(parBuf,(counter*10)+7);
	n=WrapIndex.ar(parBuf,(counter*10)+8);
	envTrig=(sTrig*WrapIndex.ar(parBuf,(counter*10)+9));


	counterE=PulseCount.ar(envTrig,resetT);
	totTime=WrapIndex.ar(parBuf,(counterE*10)+1);

	envRatio=envRatio*ccInput[0].linlin(0.0,127.0,0.001,1.0);
	fb=fb*ccInput[1].linexp(0.0,127.0,0.001,128.0);
	env2Ratio=env2Ratio*ccInput[2].linexp(0.0,127.0,0.01,1.0);
	env2Ratio1=env2Ratio1*ccInput[3].linexp(0.0,127.0,0.01,8.0);
	n=n*ccInput[4].linexp(0.0,127.0,0.001,24.0);


	totTime=totTime*(ccInput[5].linlin(0.0,127.0,0.001,4.0).round(0.0625));
	//totTime.clip(0.01,2.0);
	SendReply.kr(sTrig,'/trigBela',[freq,env2Ratio1]);
	{if((resetT>0.0),{resetT=-0.1;  });};

	//(in-27).poll(4,label:\voice);






	attack=(envRatio*totTime); //.poll(4,label:\att);
	decay=((1.0-envRatio)*totTime);//.poll(4,label:\dec);
	env1=EnvGen.ar( Env.perc(attack,decay,curve),(envTrig*br),doneAction:0).abs;
	doneE= Done.kr(env1) ;
	doneE=Duty.ar(SampleDur.ir,0, Dbufwr(doneE.bitOr(brc), envBuff));



	env3=EnvGen.ar( Env.asr(attack,1,decay,curve),sTrig,doneAction:0).abs;
	env2=ReplaceBadValues.ar(LFSaw.ar(-1.0*  (((attack+decay)*env2Ratio*(freq.reciprocal+(env3*(1.0-freq.reciprocal)))).clip((freq*env2Ratio1).reciprocal,1.0)).reciprocal  ,mul:0.5,add:0.5),post:0);
	env1=(((envAmt* env1)+(1.0-envAmt)).clip(0.0,1.0));
	fb=(env2*1.0)*fb;



	prev1 = Duty.ar(rate,0,Dbufrd(hist1)); // read from buffer
	prev2 = Duty.ar(rate,0,Dbufrd(hist2)); // read from buffer
//


	/*sig=(sig+(0.3333*CombC.ar(sig.tanh,1.0,tEnv*0.01,tEnv)))*0.75;
			// change 128 to hear the difference
	chain=FFT(LocalBuf(128), SinOsc.ar(freq+(sig*freq*1.0)),wintype:1);
	chain=PV_ConformalMap(chain,a,b);
	sig= LeakDC.ar(((IFFT(chain))*ampFb));
	sig=(sig+(2.0*MoogLadder.ar(sig,EnvFollow.ar( sig.tanh,tCoef+(Slope.ar(sig)*SampleDur.ir),freq*SinOsc.ar(freq*ratios[2],add:2.0).abs,freq*SinOsc.ar(freq*ratios[3]).abs),SinOsc.ar(freq*ratios[4],add:1.0).abs*0.46)))*0.3333333;
	sig=LeakDC.ar(((sig)) ).tanh;*/


	xyz=[prev1,prev2,(SinOsc.ar(freq+(freq*(prev1+prev2)))+Shaper.ar(~globalMemory[7],SinOsc.ar(freq,envRatio,env2Ratio).fold(0.0,1.0)))  ];



	rpt=[xyz.pow(2).sum.sqrt.pow(n).fold2(1.0), atan2(xyz[2],(xyz[0..1].pow(2).sum.sqrt)),atan2(xyz[1],xyz[0])   ];


	new=env2* ReplaceBadValues.ar([rpt[0]*(rpt[2]*n*fb).cos*(rpt[1]*n*fb).cos,
		rpt[0]*(rpt[2]*n*fb).sin*(rpt[1]*n*fb).cos],(((xyz[2]*freq+freq)*2pi).sin)!2,post:0);







	signal =Duty.ar(rate,0, [Dbufwr(new[0], hist1),Dbufwr(new[1],hist2)]); // write to buffers


	signal= EnvGate.new()* env1 *0.06* ((  SinOsc.ar(((In.ar(in,1))*((1.0-env3)*(ReplaceBadValues.ar( [prev1,prev2],post:0)))),phase:(ReplaceBadValues.ar( [rpt[1..2]],post:0)).mod(2pi))));






	OffsetOut.ar(out
	,amp*signal.tanh); //((signal.tanh)));
	//Out.ar(20,ToggleFF.ar(CoinGate.ar(0.6,envTrig))*amp*signal.tanh);
	//Select.ar( ), [DC.ar(out),DC.ar(20.0)]).poll


};returnFunc};

// Conformal mapping oscillator

(fork{





SynthDef(\fbConformal,
{
		|out=0,ampFb=1.9,freq=100.0,aP=10.01,bP=0.4,ratios=#[40.09,40.03,10.05,30.04,30.01],tEnv=0.99|


	var lb= LocalBuf.newFrom([0.0]);
	var sig;
	var chain;

	var a=aP*SinOsc.ar(ratios[0]*freq);
	var b=bP*SinOsc.ar(ratios[1]*freq);
	var tCoef=SampleDur.ir/tEnv;
		ratios=(Duty.ar(SampleDur.ir,0,ratios));


	sig=Duty.ar(SampleDur.ir,0,Dbufrd(lb)  ) ;
	sig=(sig+(0.3333*CombC.ar(sig.tanh,1.0,tEnv*0.01,tEnv)))*0.75;
			// change 128 to hear the difference
	chain=FFT(LocalBuf(128), SinOsc.ar(freq+(sig*freq*1.0)),wintype:1);
	chain=PV_ConformalMap(chain,a,b);
	sig= LeakDC.ar(((IFFT(chain))*ampFb));
	sig=(sig+(2.0*MoogLadder.ar(sig,EnvFollow.ar( sig.tanh,tCoef+(Slope.ar(sig)*SampleDur.ir),freq*SinOsc.ar(freq*ratios[2],add:2.0).abs,freq*SinOsc.ar(freq*ratios[3]).abs),SinOsc.ar(freq*ratios[4],add:1.0).abs*0.46)))*0.3333333;
	sig=LeakDC.ar(((sig)) ).tanh;
	a=Duty.ar(SampleDur.ir,0,Dbufwr(sig,lb)  ) ;

		Out.ar(out,LeakDC.ar(sig.tanh).dup);




}

).add;

1.0.wait;
x.free;
x=Synth(\fbConformal);
y.stop;
y.free;
y=
Task({
loop({
			fork{
				x.set(\ampFb,0.1.exprand(1.0),
					\freq,50.0.exprand(10000.0),
					\aP,0.01.exprand(1.0),
					\bP,0.01.exprand(1.0),\ratios,Ref(((0.01.exprand(1.0))*Scale.choose.ratios.wrapExtend(5))),
					\tenv,(0.00001.exprand(0.1)))};
			0.1.wait;

	})});
y.start
})


/// ////// //////
// FFT resonator??

(
SynthDef("testFftFb", { arg out=0,thresh=4.0;
    var inA, chainA, chainB, chain;
    var lb=LocalBuf(1,1),wb;


	inA = WhiteNoise.ar()*EnvGen.ar(Env.perc(0.0001,0.01),Trig.ar(Pulse.ar(1.0,0.2,1,-0.5)));

	wb=Duty.ar(SampleDur.ir,0,BufRd.ar(1,lb,DC.ar(0.0)));
    chainA = FFT(LocalBuf(2048), wb);
    chainB = FFT(LocalBuf(2048), inA);
	chain=PV_Mul(chainA,chainA);
	chain = PV_Add(chain, chainB);
	chain=PV_MagBelow(chain,thresh);
	chain=IFFT(chain);
	wb=Duty.ar(SampleDur.ir,0,BufWr.ar(chain,lb,DC.ar(0.0)));


    Out.ar(out,   (chain.poll).dup);
}).play(s);
s.scope;
)










