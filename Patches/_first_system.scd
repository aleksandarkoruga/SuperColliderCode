~bus=Bus.audio(s,4);


~bus.index



(
  var bus=~bus;




SynthDef(\FMcascade,
{


|freq=50.0,modAmp=10.0,ratioM=1.2,attack=0.01,decay=0.1,idx=900.0,stepF=0.1,stepI=1.0,rTime=0.01,fb=2.0,amp=1.0,bus=0,dur=0|
	//
var	xx, yy, rate, buff,prevMem=0.0,memIdx=0.0,prev=0.0,modulations,indexes,chain=6,memLen=2,
		env, envA,envB,envAmp,signal,freqM,totTime,lastArg,

		funcFM={
		// function for FM harmonics
			|x=8,y=8,startF=300.0,startS=1.1,stepS=0.1|
			var series=Array.series(y,startS,stepS),out=[];

			series.do({|item,i| out=out.add(Array.geom(x,startF,item))});

			out

		       };

	    // //////////////
		freqM=ratioM*freq;
		totTime=attack+decay;

	modulations=LocalBuf.newFrom (funcFM.value(chain,memLen,freqM,stepS:stepF).flatten);
	indexes=LocalBuf.newFrom( funcFM.value(chain,memLen,idx,stepS:stepI).flatten.reverse);

	rate = s.sampleRate;
	prevMem=memIdx;
	memIdx=Duty.ar(rate.reciprocal,0,  Dstutter(rTime*rate, Dwhite(0,memLen-1)));

	env=EnvGen.ar(Env.new([prevMem,memIdx],[rTime*0.5]),Changed.ar(memIdx));
	envA=EnvGen.ar(Env.perc(attack.explin(0.1,totTime,0.00000001,totTime),decay.explin(0.1,totTime,0.00000001,totTime),curve:(-1.0*(1.0/decay))),1);
		envB=EnvGen.ar(Env.perc(attack.explin(0.1,totTime,0.00000001,totTime),decay.explin(0.1,totTime,0.00000001,totTime),curve:-50.0*(1.0/decay)),1);

	envAmp=EnvGen.ar(Env.perc(attack,decay,curve:-4.60*(1.0/decay)),1,doneAction:2);



	buff = LocalBuf(1);




	prev = Duty.ar(1/rate,0,Dbufrd(buff)); // read from buffer
	xx = SinOsc.ar(freqM+(prev*fb));
	chain.do({
		|i|
		var tIdx,tFreq;
			tIdx=BufRd.ar(1,indexes,Duty.ar(rate.reciprocal,0,i+(env*chain)),1);
			tFreq=BufRd.ar(1,modulations,Duty.ar(rate.reciprocal,0,(i+(env*chain))),1);
			xx=SinOsc.ar(  (tIdx *xx*envA)  +(fb*prev)+( tFreq+(envB*(modAmp*(1.0/(attack+1.0)))*tFreq)));
		});
		lastArg=((idx*xx*envA)+freq+(envB*(modAmp*(1.0/(attack+1.0))*freq)));
		xx=  ( SinOsc.ar(lastArg)+SawDPW.ar(lastArg));

	yy = Dbufwr(xx, buff); // write to buffer
signal=(Duty.ar(1 / rate, 0, yy)*envAmp) * 0.1.dup;

		OffsetOut.ar(bus,amp*signal);



};
).add;


Tdef(\x, {

	var
	markov= [MarkovFb.new(16),MarkovFb.new(32)],
	scale=16.0,
	idx=Pseq([400.01,670.05,900.05,200.07,3000.0,2000.06,1000.0,100.5],inf).loop.asStream,
	fb=Pseq([11000.01,600.0,1000.05,0.07,30.0,4000.06,1.0,19990.5],inf).loop.asStream,
	modAmp=Pn(Plazy({Pseq(Array.geom(16,exprand(0.01,0.08),exprand(0.09,0.1)).scramble,1)}),inf).loop.asStream;

	loop({

		Synth("FMcascade",[
		\bus,bus.index+2,
		\freq,(markov[0].next+48).midicps,//if((exprand(0.001,0.2)).coin,exprand(78,84).midicps,exprand(60,72).midicps) ,
		\ratioM,(markov[0].current.mod(3)+(1.0/rrand(1,12))),
		\decay,((markov[1].next+1.0))*(if(rrand(0.001,0.1).coin,{0.000001},{exprand(0.003,0.2)})),

		\legato,0.2,
        \amp,-3.0.dbamp,
		\attack,(markov[1].current+1.0)*rrand(0.01,0.1),
		\fb,fb.next,
		\rTime,(markov[1].current+1.0)*rrand(0.01,1.7),
		\stepI,rrand(0.0001,6.0),
		\idx,idx.next,
		\modAmp,modAmp.next]);
	((0.7*(markov[1].current+1.0))/(if(    (exprand(0.01,0.2)).coin,{14},   {exprand(7.0,8.0)}     ))       ).wait; }) });

Tdef(\y, {

	var
	markov= MarkovFb.new(16),
	idx=Pseq([400.01,0.05,100.05,0.07,3000.0,7890.06,178.0,100.5],inf).loop.asStream,
	fb=Pseq([90.0,0.02,0.05,0.07,30.0,4000.06,1.0,67.0],inf).loop.asStream,
	modAmp=Pn(Plazy({Pseq(Array.geom(16,exprand(1.0,1.2),exprand(1.0,1.5)).scramble,1)}),inf).loop.asStream;

	loop({  Synth("FMcascade",[
		\bus,bus.index,
		\freq,(markov.next+30).midicps,//if((exprand(0.001,0.2)).coin,exprand(78,84).midicps,exprand(30,39).midicps) ,
		\ratioM,(rrand(0,7)+(1.0/rrand(1,12))),
		\decay,if(exprand(0.1,0.2).coin,{0.0001},{exprand(0.3,1.0)}),

		\legato,0.2,

		\attack,exprand(0.0001,0.01),
		\fb,fb.next,
		\rTime,exprand(0.0004,0.5),
		\stepI,exprand(10,100),
		\idx,idx.next,
		\modAmp,modAmp.next]);
	(0.7/(if(    (exprand(0.01,0.2)).coin,{14},   {exprand(7.0,8.0)}     ))       ).wait; }) });





Ndef(\chop, {
		|input=0.0,out=0,bpm=85.714,length=1.0,freqScale=0.5,windowSize=0.12|
	var totalTime=length*((bpm/60.0).reciprocal),
		divisor=8.0,
		frames=totalTime*s.sampleRate,
		buffer=LocalBuf.new(frames,1),
		rate=1.0,bufTime=0.0,
		signal,
	    wrPtr,
	    fxEnv,
		rdPtr,rdFunc,rdFunc2,rdPtr2,noise1,noise2;

	freqScale=Duty.ar((totalTime/divisor).clip((1.0/SampleRate.ir),totalTime),0,Dwhite(0.1,1.2,inf));
	noise1=Duty.ar((totalTime/divisor).clip((1.0/SampleRate.ir),totalTime),0,Dwhite(0.1,4.0,inf));
	noise2=Duty.ar((totalTime/divisor).clip((1.0/SampleRate.ir),totalTime),0,Dwhite(0.1,4.0,inf));


	//rate= Duty.ar((totalTime/divisor).clip((1.0/SampleRate.ir),totalTime),0,Dbrown(0.1,2.0,0.05));


	wrPtr=Phasor.ar(0, (BufRateScale.kr(buffer) * rate), 0.0, BufFrames.kr(buffer));
    bufTime=BufFrames.ir(buffer)*SampleRate.ir().reciprocal;
	input=\in1.ar();

	rdFunc=Duty.ar((totalTime/divisor).clip((1.0/SampleRate.ir),totalTime),0, Dwrand([0.0,(Dwhite(1,(divisor-1)).floor()/divisor)],[(1.0-(wrPtr/BufFrames.ir(buffer))),(wrPtr/BufFrames.ir(buffer))],inf)  );

	rdFunc2=SinOsc.ar(( Latch.ar((40.0+(40.0* BrownNoise.ar())).linexp(0,80.0,12.0,300.0),Impulse.ar((freqScale*divisor)/totalTime)) ))   ;


	rdPtr=(Wrap.ar(((wrPtr/BufFrames.ir(buffer)) - rdFunc)+1.0));
	rdPtr2=Wrap.ar((wrPtr - rdFunc2)+1.0);
		BufWr.ar(input,buffer,wrPtr,1);

	fxEnv=EnvGen.ar(Env.perc(totalTime*noise1,totalTime*noise2),Impulse.ar((freqScale*0.1)/totalTime));

	signal=Warp1.ar(1,buffer,rdPtr,freqScale,windowSize.clip(0.001,(1.0-rdPtr)*bufTime),windowRandRatio:0.07);
	signal=(signal*(1.0-fxEnv))+(BufRd.ar(1,buffer,rdPtr2*BufFrames.ir(buffer))*fxEnv);
		OffsetOut.ar(out,signal);


}    );


Tdef(\x).play;
Tdef(\y).play;



Ndef(\chop) <<>.in1 Ndef(\drum,{(Mix.ar(Ndef.ar(\rev)++In.ar(bus.index,2)))});
Ndef(\rev,{
	(1.0-Amplitude.ar(LPF.ar(In.ar(bus.index,1)*10.0,80.0).tanh))*((1.0-Amplitude.ar((In.ar(bus.index+2,1)*10.0).tanh))* FreeVerb.ar(Mix.ar( In.ar(bus.index+2,2).tanh),0.6,0.9,0.2,2.0)+(Amplitude.ar((In.ar(bus.index+2,1)*10.0).tanh)*In.ar(bus.index+2,1).tanh))
});
//                                          if too loud multiply sig
Ndef(\mix,{  var sig=Ndef.ar(\chop); (2.9*Ndef.ar(\rev).at(0)!2+(sig*0.7))}  ).play;
Ndef(\mix).reshaping = \elastic;
Ndef(\mix).mold(2);



)




Ndef(\mix).scope
s.scope
spectroscope
~bus.free
Ndef(\rev).stop;


