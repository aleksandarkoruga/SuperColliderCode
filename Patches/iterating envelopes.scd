({   var e;
	var b=LocalBuf.newFrom([1.0]);
	var d;
	var br;
	var brc;
	var trig=Trig.ar(Dust.ar(4));


	br=Duty.ar(SampleDur.ir,0,Dbufrd(b));
	brc=1-PulseCount.ar(br).clip(0,1);
	e	=(EnvGen.ar(Env.perc(0.01,0.7 ),br*trig   )).poll;
	d= Done.kr(e) ;
	d=Duty.ar(SampleDur.ir,0, Dbufwr(d.bitOr(brc), b));
	Out.ar(0,Saw.ar(330 )*e);


}.play)