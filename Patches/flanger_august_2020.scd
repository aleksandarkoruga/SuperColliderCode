
Environment.clear

(// read a whole sound into memory
b = Buffer.read(s,"/Users/aleksandar/Music/Loopmasters.KV.Bala.Krishnan.Tabla.Sessions.WAV.REX/TSE_WAV_LOOPS/TSE_120_E/TSE_120_E_9_Tabla_Ens_1_2-4.wav");

// make a simple sampler instrument
SynthDef("LoopBuf",{
    arg out=0, bufnum=0, rate=1, glide=0, gate=1, loopRel=0, startPos=0, startLoop, endLoop, ipol=2;
    var env, signal;
    rate = Lag.kr(rate, glide);
    env = EnvGen.ar(Env.adsr(0.1,0.2,1,2), gate, doneAction: 2);
    signal = LoopBuf.ar(1,bufnum, BufRateScale.kr(bufnum) * rate, gate+loopRel, startPos, startLoop, endLoop, ipol);
    Out.ar(out, (signal * env).dup);
}).send(s);
)


b=Buffer.read(s,"/Users/aleksandar/Music/drum/Drum and Bass Live-170bpm.aif");
b=Buffer.read(s,"/Users/aleksandar/Downloads/T3_2017_spunti_e_materiali_MaxMSP/03_Test Sounds/drumLoop.aif");



b.numFrames




(

f=SynthDef(\flangDel,
	{
		|busIn=0,busOut=0,modF=1.0,time=0.4,totTime=1.0,modAmt=0.1,fb=0.01,fmAmt=0.1,mix=0.5,a=10.0,b=10.0,c=10.0,d=10.0,decay=0.9|
		var input=In.ar(busIn,1),signal=0.0,signal1=0.0,lIn,signalAmp,chain,chain1,chainRes,chainRes1;
		var rate=SampleRate.ir.reciprocal;
		var par1,par2;

		lIn=LocalIn.ar(2);
		lIn=LeakDC.ar(ReplaceBadValues.ar(lIn.tanh,post:0)) ;

		time=time+(fmAmt*SinOsc.ar(modF+((modF*modAmt)* SinOsc.ar(modF,mul:(modF*modAmt))),mul:(time*modAmt)));



		par1=[ReplaceBadValues.ar( Amplitude.ar(signal*10.0).tanh,1.0,post:0),(totTime*ReplaceBadValues.ar(Amplitude.ar(signal*10.0).tanh,0.0,post:0))];
		par2=[ReplaceBadValues.ar( Amplitude.ar(signal1*10.0).tanh,1.0,post:0),(totTime*ReplaceBadValues.ar(Amplitude.ar(signal1*10.0).tanh,0.0,post:0))];

		signal= DelayC.ar(input- ((1.0-(fb*Slew.ar(par1[0],1.0,0.1)))*lIn[0]), totTime,(time.wrap(ControlRate.ir.reciprocal,totTime)- ControlRate.ir.reciprocal ));
		signal1= DelayC.ar(input+ ((1.0-(fb*Slew.ar(par2[0],1.0,0.1)))*lIn[1]), totTime,(time.wrap(ControlRate.ir.reciprocal,totTime)- ControlRate.ir.reciprocal ));

		signal=ReplaceBadValues.ar(Spring.ar(signal,(par1[0]*100.0).abs.wrap(0.1,1.0),(par1[1]*100.0).abs.wrap(0.1,0.9)),post:0);
		signal1=ReplaceBadValues.ar(Spring.ar(signal,(par2[0]*100.0).abs.wrap(0.1,1.0),(par2[1]*100.0).abs.wrap(0.1,0.9)),post:0);
		signal=ReplaceBadValues.ar(signal,post:0);
		signal1=ReplaceBadValues.ar(signal1,post:0);



		signalAmp= DelayN.ar((Amplitude.ar(input,0.00001,0.00001)),  totTime, time.wrap(s.sampleRate.reciprocal,totTime)- ControlRate.ir.reciprocal );

		chain = FFT(LocalBuf(2048), signal);
		chain1= FFT(LocalBuf(2048), signal1);

		chain=PV_MagShift(chain,
			ReplaceBadValues.ar(((a*Amplitude.ar(input,0.000001,decay,add:-0.5)).wrap2(1.0)*2048.0).wrap2(2048.0),1.0,post:0),

			ReplaceBadValues.ar(((b*Amplitude.ar(signalAmp*input,0.000001,decay,add:-0.5)).wrap2(1.0)*2048.0).wrap2(2048.0),1.0,post:0));
		chain=PV_MagAbove(chain,0.01);

		chain1=PV_MagShift(chain1,
			ReplaceBadValues.ar(((c*Amplitude.ar(input,0.000001,decay,add:-0.5)).wrap2(1.0)*2048.0).wrap2(2048.0),1.0,post:0),

			ReplaceBadValues.ar(((d*Amplitude.ar(signalAmp*input,0.000001,decay,add:-0.5)).wrap2(1.0)*2048.0).wrap2(2048.0),1.0,post:0));

	chain1=PV_MagAbove(chain1,0.01);
		chain=PV_Morph(chain,chain1,mix*SinOsc.ar(modF).abs);
		chain1=PV_Mul(chain1,chain1);
		chain1=PV_Add(chain1,chain);


		chainRes=(CompanderD.ar((IFFT(chain)*1000.0).tanh,slopeBelow: 10,
        slopeAbove: 1,
        clampTime: 0.01,
        relaxTime: 0.01));
		chainRes1=(CompanderD.ar((IFFT(chain1)*1000.0).tanh,slopeBelow: 10,
        slopeAbove: 1,
        clampTime: 0.01,
        relaxTime: 0.01));


		signal=LeakDC.ar((((1.0-mix)*signal)+((mix)*chainRes)).wrap2(1.0));
		signal1=LeakDC.ar((((1.0-mix)*signal1)+((mix)*chainRes1)).wrap2(1.0));



		//local =Duty.ar(rate,0, [Dbufwr(signal, s1),Dbufwr(signal1,s2)]);
		signal= FreeVerb.ar(signal.tanh,1.0-par1[0].clip(0.0,1.0),par1[0].wrap(0.1,0.9),par2[1].wrap(0.1,0.9)).tanh;
		signal1=FreeVerb.ar(signal1.tanh,1.0-par2[0].clip(0.0,1.0),par2[0].wrap(0.1,0.9),par1[1].wrap(0.1,0.9)).tanh;

		LocalOut.ar([signal,signal1]);
		ReplaceOut.ar(busOut,Amplitude.ar( signalAmp,0.0000001,decay)*ReplaceBadValues.ar(LeakDC.ar(((signal+signal1)).tanh),post:0));


});
//


f.add;
)
(
~s1.free;
~s2.free;
~s1=Synth.before(~chopSynthIn,"flangDel",[\busIn,~bus.index,\busOut,~bus.index]);
~s2=Synth.before(~chopSynthIn,"flangDel",[\busIn,~bus.index+1,\busOut,~bus.index+1]);
)
~s1=Synth("flangDel",[\busIn,0,\busOut,0]);
~s2=Synth("flangDel",[\busIn,1,\busOut,1]);

~s1.set(\time,200.reciprocal,\fb,2.89,\fmAmt,100.4,\mix,1.0,\modF,100.01,\modAmt,10.1,\a,10.01,\b,100.001,\c,10.001,\d,10.0001,\decay,3.0);

~s2.set(\time,200.reciprocal,\fb,0.89,\fmAmt,100.4,\mix,1.0,\modF,100.01,\modAmt,10.1,\a,10.01,\b,100.001,\c,10.001,\d,10.0001,\decay,3.0);

)

(
~s1.set(\time,100.1.reciprocal,\fb,0.10,\fmAmt,0.1,\mix,0.4,\modF,660.2,\modAmt,0.001,\a,10.1,\b,10.1,\c,10.001,\d,10.001,\decay,0.3);


~s2.set(\time,100.1.reciprocal,\fb,2.0,\fmAmt,1000.0,\mix,0.55,\modF,1000.0,\modAmt,0.001,\a,10.1,\b,0.000001,\c,0.00001,\d,10.000001,\decay,0.7);

)


(~s2.free;
~s1.free
)

(
~s1=Synth.before(~mixIO,"flangDel",[\busIn,~bus.index+6,\busOut,~bus.index+6]);
~s2=Synth.before(~mixIO,"flangDel",[\busIn,~bus.index+7,\busOut,~bus.index+7]);
)


(
~s1=Synth("flangDel",[\busIn,0,\busOut,0]);
~s2=Synth("flangDel",[\busIn,1,\busOut,1]);
)

~s3=Synth("imp_ulse",[\totTime,0.2,\freq,7000.0,\modAmt,0.9]);
~s3
(
f=Task({inf.do({arg i;{~s3=Synth("imp_ulse",[\totTime,0.2,\freq,40.0.exprand(500.0),\modAmt,0.9])}.fork;
	0.2.wait
})}).start;

)
f=f.start
f.stop
~s3.free

(
SynthDef(\imp_ulse,{ |freq=440.0,phase=0.0,totTime=0.3,envRatio=0.001,modAmt=0.3|var signal,env;
	env=EnvGen.ar( Env.perc(totTime*envRatio,totTime*(1.0-envRatio)),doneAction:2);
	signal=Impulse.ar(freq+(modAmt*SinOsc.ar(freq)*freq*env),phase);
	Out.ar(0,signal.dup) }).add;

)




// start playback
s.sendMsg("/s_new", "LoopBuf", s.nextNodeID, 0, 1, \bufnum, b.bufnum, \startLoop, 0, \endLoop, b.numFrames,\rate,1.0);


(
t.stop;
t = Task({
    inf.do({ arg i;
		 ~s2.set(
			\time,100.3.exprand(300.0).reciprocal,
			\modF,0.01.exprand(560.01),
			\modAmt,(0.00001.exprand(80.0001)),
			\mix,0.01.exprand(0.1),
			\fb,0.92.exprand(0.999),
			\fmAmt,10.0.exprand(70.2),
			\decay,0.02.exprand(5.1),
			\a,78.0001.rand2,\b,0.0008.rand2,\c,0.00002.rand2,\d,0.2004.rand2);


		~s1.set(
			\time,450.0001.exprand(780.1).reciprocal,
			\modF,0.01.exprand(7870.01),
			\modAmt,(0.0001.exprand(78.3)),
			\mix,0.01.exprand(0.2),
			\fb,0.19.exprand(0.98),
			\fmAmt,10.00004.exprand(780.001),
			\decay,0.01.exprand(3.1),
			\a,56.009.rand2,\b,0.0007.rand2,\c,0.9001.rand2,\d,0.0003.rand2);
        4.0*(120.0/60.0).rand.reciprocal.wait;
    });
});


t.start;
)
t.stop;
t.start;

(
~s1.set(\time,200.reciprocal,\fb,0.1,\fmAmt,10.4,\mix,0.99,\modF,100.01,\modAmt,10.1,\a,1000.01,\b,1000.001,\c,1000.001,\d,1000.0001,\decay,3.0);
)

s.scope




(
~s2.set(\time,210.reciprocal,\fb,0.999,\fmAmt,0.1,\mix,0.5,\modF,70.0,\modAmt,0.2,\a,10.1,\b,0.1,\c,10.1,\d,0.001);


)


(
~s2.free;
~s1.free
)
s.scope
