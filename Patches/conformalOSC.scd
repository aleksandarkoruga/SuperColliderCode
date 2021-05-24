
(
SynthDef("help-mul", { arg out=0,thresh=4.0;
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
FreqScope.new(400, 200, 0, server: s);

sqrt(3)

Polynomial[4,4,9].findRoots()

Complex.new(1,1).pow(0.5)


(
var newt= {
	|poly,prev,c,a|
	var roots=poly.findRoots().postln;
	var deriv=poly.evalDerivs(prev);
	var next=prev-(deriv[0]/deriv[1])+c;
	next
};

var poly= Polynomial[0,2,3,1,2];
var val=Complex(0.0,0.0);

x=100.collect({ val=newt.value(poly,val,Complex(0.1,-0.4),0.4)  });






)
x.collect({|item|[item.real,item.imag]}).flop.at(0).plot


.evalDerivs(0.4)
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
y.start
s.scope






