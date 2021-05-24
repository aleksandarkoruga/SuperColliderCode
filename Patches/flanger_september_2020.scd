


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

